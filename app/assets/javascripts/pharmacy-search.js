$(() => {
  if ($('#payer-select').length > 0) {
    updatePharmacyNetworkList({ target: { value: $('#payer-select').val() } });
    updatePharmacyZip({ target: { value: $('#zip-input').val() } });
    updatePharmacyZip({ target: { value: $('#radius-input').val() } });
    updatePharmacyCity({ target: { value: $('#city-input').val() } });
    updatePharmacyName({ target: { value: $('#name-input').val() } });
  }
});

const updatePharmacyNetworkList = function (event) {
  updatePharmacySearchParam(event, 'network');

  if(event.target.value === '') {
    $('#network-select').html('');
  } else {
    fetch(`/pharmacies/networks.json?payer_id=${event.target.value}`)
      .then(response => response.json())
      .then(networks => {
        const htmlString = networks
              .map(network => `<option value="${network.value}">${network.name}</option>`)
              .join('\n');
        $('#network-select').html(htmlString);
        updatePharmacyNetwork({ target: { value: $('#network-select').val() } });
      });
  }
};

let pharmacyParams = {};

const updatePharmacySearchParam = function(event, param) {
  pharmacyParams[param] = event.target.value;
};

const updatePharmacyNetwork = function (event) {
  updatePharmacySearchParam(event, 'network');
};

const updatePharmacyZip = function (event) {
    updatePharmacySearchParam(event, 'zip');
};
const updatePharmacyRadius = function (event) {
  updatePharmacySearchParam(event, 'radius');
};

const updatePharmacyCity= function (event) {
  updatePharmacySearchParam(event, 'city');
};

const updatePharmacyName = function (event) {
  updatePharmacySearchParam(event, 'name');
};

const submitPharmacySearch = function (_event) {
  const params = Object.entries(pharmacyParams)
        .filter(([key, value]) => value && value.length > 0)
        .map(([key, value]) => `${key}=${value}`)
        .join(`&`);

  console.log(params);
  fetchPharmacies(params);
};

const fetchPharmacies = function (params) {
 fetch(`/pharmacies/search.json?${params}`)
    .then(response => response.json())
    .then(response => 
      {
      const { pharmacies, nextPage, previousPage, searchParams } = response;
      updatePharmacies(pharmacies);
      updatePharmacyNavigationButtons(nextPage, previousPage);
      updatePharmacyQuery(searchParams);
    }
    );
};


const updatePharmacies = function (pharmacies) {
  const rows = pharmacyRows(pharmacies);
  $('#pharmacies-table').html(rows);
};

const updatePharmacyNavigationButtons = function (nextPage, previousPage) {
  const hasNextPage = nextPage !== 'disabled';
  const hasPreviousPage = previousPage !== 'disabled';

  if (hasNextPage) {
    $('#next-button').removeClass('disabled');
  } else {
    $('#next-button').addClass('disabled');
  }
  if (hasPreviousPage) {
    $('#previous-button').removeClass('disabled');
  } else {
    $('#previous-button').addClass('disabled');
  }
  updatePharmacyNavigationActions(hasNextPage, hasPreviousPage);
};

const updatePharmacyNavigationActions = function (hasNextPage, hasPreviousPage) {
  $('#next-button').off('click');
  $('#previous-button').off('click');
  if (hasNextPage) {
    $('#next-button').on('click', () => fetchPharmacies('page=next'));
  }
  if (hasPreviousPage) {
    $('#previous-button').on('click', () => fetchPharmacies('page=previous'));
  }
};

const pharmacyHeaderRow = `
<tr>
  <th>Name</th>
  <th>Phone/Fax</th>
  <th>Address</th>
</tr>
`;




const pharmacyRows = function (pharmacies) {
  if (pharmacies.length > 0) {
    return pharmacyHeaderRow + pharmacies.map(pharmacy => {
      return `
          <tr>
            <td>
              <a href="/locations/${pharmacy.id}">
                ${pharmacy.name}
              </a>
            </td>
            <td>${pharmacy.telecom.join('<br>')}</td>
            <td>${pharmacy.address}</td>
          </tr>
        `;
    }).join('');
  } else {
    return `
      <tr>
        <th>No pharmacies found</th>
      </tr>
    `;
  }
};

const updatePharmacyQuery = function (query){
  row = pharmacyQuery(query);
  $('#pharmacy-query-table').html(row)
};

const pharmacyQuery = function (query) {
  if(query.length > 0){
   return `
   <tr>
     <td>
      ${query}
     </td>
   </tr>
   `;
  }
 };
 