$(() => {
  if ($('#payer-select').length > 0) {
    updateProviderNetworkList({ target: { value: $('#plan-select').val() } });
    updateProviderZip({ target: { value: $('#zip-input').val() } });
    updateProviderCity({ target: { value: $('#city-input').val() } });
    updateProviderSpecialty({ target: { value: $('#specialty-select').val() } });
    updateProviderName({ target: { value: $('#name-input').val() } });
    updateProviderActiveDate({ target: { value: $('#active-input').val() } });
    updateProviderActive({ target: { value: $('#is-active-input').val() } });
    updateProviderNewPatient({ target: { value: $('#new-patient-input').val() } });
  }
});

const updateProviderNetworkList = function (event) {
  updateProviderSearchParam(event, 'practitionerrole-network');
  if(event.target.value === '') {
    $('#plan-select').html('');
  } else {
    networksByPlan = JSON.parse(event.target.getAttribute("data-networksByPlan"))
      htmlString = networksByPlan[event.target.value]
          .map(network => `<option value="${network.reference}">${network.display}</option>`).join('\n');
        $('#network-select').html(htmlString);
        updateProviderNetwork({ target: { value: $('#network-select').val() } });
      }
};


const updateProviderNetworkList_old = function (event) {
  updateProviderSearchParam(event, 'network');

  if(event.target.value === '') {
    $('#network-select').html('');
  } else {
     fetch(`/providers/networks.json?payer_id=${event.target.value}`)
      .then(response => response.json())
      .then(networks => {
        const htmlString = networks
              .map(network => `<option value="${network.value}">${network.name}</option>`)
              .join('\n');

        $('#network-select').html(htmlString);
        updateProviderNetwork({ target: { value: $('#network-select').val() } });
      });
  }
};

let providerParams = {};
const updateProviderSearchParam = function(event, param) {
  providerParams[param] = event.target.value;
};

const updateProviderNetwork = function (event) {
  updateProviderSearchParam(event, 'practitionerrole-network');
};

const updateProviderZip = function (event) {
  updateProviderSearchParam(event, 'zip');
};

const updateProviderRadius = function (event) {
  updateProviderSearchParam(event, 'radius');
};

const updateProviderCity= function (event) {
  updateProviderSearchParam(event, 'city');
};

const updateProviderSpecialty = function (event) {
  updateProviderSearchParam(event, 'specialty');
};

const updateProviderName = function (event) {
  updateProviderSearchParam(event, 'name');
};

const updateProviderActive = function (event) {
  console.log("in here!");
  updateProviderSearchParam(event, 'active');
}

const updateProviderNewPatient = function (event) {
  updateProviderSearchParam(event, 'practitionerrole-new-patient');
}


const updateProviderActiveDate = function (event) {
  providerParams['date'] = 'le' + event.target.value + '&date=ge' + event.target.value;
};

const submitProviderSearch = function (_event) {
  const params = Object.entries(providerParams)
        .filter(([key, value]) => value && value.length > 0)
        .map(([key, value]) => `${key}=${value}`)
        .join(`&`);

  console.log(params);

  fetchProviders(params);
};

const fetchProviders = function (params) {
  console.log(`/providers/search.json?${params}`);
  fetch(`/providers/search.json?${params}`)
    .then(response => response.json())
    .then(response => {
      const { providers, nextPage, previousPage, searchParams } = response;
      updateProviders(providers);
      updateProviderNavigationButtons(nextPage, previousPage);
      updateProviderQuery(searchParams);
    });
};

const updateProviders = function (providers) {
  const rows = providerRows(providers);
  $('#providers-table').html(rows);
};

const updateProviderNavigationButtons = function (nextPage, previousPage) {
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
  updateProviderNavigationActions(hasNextPage, hasPreviousPage);
};

const updateProviderNavigationActions = function (hasNextPage, hasPreviousPage) {
  $('#next-button').off('click');
  $('#previous-button').off('click');
  if (hasNextPage) {
    $('#next-button').on('click', () => fetchProviders('page=next'));
  }
  if (hasPreviousPage) {
    $('#previous-button').on('click', () => fetchProviders('page=previous'));
  }
};

const providerHeaderRow = `
  <tr>
    <th>Name</th>
    <th>Phone/Fax</th>
    <th>Address</th>
    <th>Specialties</th>
  </tr>
`;

const providerImageUrl = function (provider) {
     return provider.photo
};

const providerRows = function (providers) {
  if (providers.length > 0) {
    return providerHeaderRow + providers.map(provider => {
      return `
        <tr>  
          <td>
            <a href="/practitioners/${provider.id}">
              <img class="list-photo" src="/assets/${providerImageUrl(provider)}">
              <br>
              ${provider.name}
            </a>
          </td>
          <td>${provider.telecom.join('<br>')}</td>
          <td><a href="${provider.gaddress}">${provider.address[0]} </a></td>
          <td>${provider.specialty.join('<br>')}</td>
        </tr>
      `;
    }).join('');
  } else {
    return `
      <tr>
        <th>No providers found</th>
      </tr>
    `;
  }
};

const updateProviderQuery = function (query){
  content = providerQuery(query);
  $('#provider-query').html(content)
};

const providerQuery = function (query) {
  if(query.length > 0){
    return `
      <p>Query to server</p>
      <p class="query">
        ${query}
      </p>
    `;
  }
};
 