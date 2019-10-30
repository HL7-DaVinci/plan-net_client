$(() => {
  if ($('#payer-select').length > 0) {
    updateNetworkList({ target: { value: $('#payer-select').val() } });
    updateZip({ target: { value: $('#zip-input').val() } });
    updateCity({ target: { value: $('#city-input').val() } });
    updateSpecialty({ target: { value: $('#specialty-select').val() } });
    updateName({ target: { value: $('#name-input').val() } });
  }
});

const updateNetworkList = function (event) {
  updateSearchParam(event, 'network');

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
        updateNetwork({ target: { value: $('#network-select').val() } });
      });
  }
};

let searchParams = {};
const updateSearchParam = function(event, param) {
  searchParams[param] = event.target.value;
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

const updateSpecialty = function (event) {
  updateSearchParam(event, 'specialty');
};

const updateName = function (event) {
  updateSearchParam(event, 'name');
};

const submitProviderSearch = function (_event) {
  const params = Object.entries(searchParams)
        .filter(([key, value]) => value && value.length > 0)
        .map(([key, value]) => `${key}=${value}`)
        .join(`&`);

  console.log(params);

  fetchProviders(params);
};

const fetchProviders = function (params) {
  fetch(`/providers/search.json?${params}`)
    .then(response => response.json())
    .then(response => {
      const { providers, nextPage, previousPage } = response;
      updateProviders(providers);
      updateNavigationButtons(nextPage, previousPage);
    });
};

const updateProviders = function (providers) {
  const rows = providerRows(providers);
  $('#providers-table').html(rows);
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
    $('#next-button').on('click', () => fetchProviders('page=next'));
  }
  if (hasPreviousPage) {
    $('#previous-button').on('click', () => fetchProviders('page=previous'));
  }
};

const headerRow = `
<tr>
  <th>Name</th>
  <th>Phone/Fax</th>
  <th>Address</th>
  <th>Specialties</th>
</tr>
`;

const providerImageUrl = function (provider) {
  return provider.gender === 'male' ? '/assets/man-user.svg' : '/assets/woman.svg';
};

const providerRows = function (providers) {
  if (providers.length > 0) {
    return headerRow + providers.map(provider => {
      return `
          <tr>
            <td>
              <a href="/practitioners/${provider.id}">
                <img class="list-photo" src="${providerImageUrl(provider)}">
                <br>
                ${provider.name}
              </a>
            </td>
            <td>${provider.telecom.join('<br>')}</td>
            <td>${provider.address[0]}</td>
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
}
