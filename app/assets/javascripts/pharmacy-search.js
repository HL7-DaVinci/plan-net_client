$(() => {
  if ($('#payer-select').length > 0) {
    updateNetworkList({ target: { value: $('#payer-select').val() } });
    updateZip({ target: { value: $('#zip-input').val() } });
    updateCity({ target: { value: $('#city-input').val() } });
    updateName({ target: { value: $('#name-input').val() } });
  }
});

const updateNetworkList = function (event) {
  updateSearchParam(event, 'network');

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
        updateNetwork({ target: { value: $('#network-select').val() } });
      });
  }
};

let pharmacyParams = {};
const updateSearchParam = function(event, param) {
  pharmacyParams[param] = event.target.value;
};

const updateNetwork = function (event) {
  updateSearchParam(event, 'network');
};

const updateZip = function (event) {
  updateSearchParam(event, 'zip');
};

const updateCity= function (event) {
  updateSearchParam(event, 'city');
};

const updateName = function (event) {
  updateSearchParam(event, 'name');
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
    .then(response => {
      const { pharmacies, nextPage, previousPage } = response;
      updatePharmacies(pharmacies);
      updateNavigationButtons(nextPage, previousPage);
    });
};

const updatePharmacies = function (pharmacies) {
  const rows = pharmacyRows(pharmacies);
  $('#pharmacies-table').html(rows);
};

const updateNavigationButtons = function (nextPage, previousPage) {
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
  updateNavigationActions(hasNextPage, hasPreviousPage);
};

const updateNavigationActions = function (hasNextPage, hasPreviousPage) {
  $('#next-button').off('click');
  $('#previous-button').off('click');
  if (hasNextPage) {
    $('#next-button').on('click', () => fetchPharmacies('page=next'));
  }
  if (hasPreviousPage) {
    $('#previous-button').on('click', () => fetchPharmacies('page=previous'));
  }
};

const headerRow = `
<tr>
  <th>Name</th>
  <th>Phone/Fax</th>
  <th>Address</th>
</tr>
`;

const pharmacyRows = function (pharmacies) {
  if (pharmacies.length > 0) {
    return headerRow + pharmacies.map(pharmacy => {
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
}
