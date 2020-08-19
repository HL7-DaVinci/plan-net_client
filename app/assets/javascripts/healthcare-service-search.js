$(() => {
  if ($('#payer-select').length > 0) {
    updateHealthcareServiceNetworkList({ target: { value: $('#payer-select').val() } });
    updateHealthcareServiceZip({ target: { value: $('#zip-input').val() } });
    updateHealthcareServiceZip({ target: { value: $('#radius-input').val() } });
    updateHealthcareServiceCity({ target: { value: $('#city-input').val() } });
    updateHealthcareServiceName({ target: { value: $('#name-input').val() } });
  }
});

const updateHealthcareServiceNetworkList = function (event) {
  updateHealthcareServiceSearchParam(event, 'network');

  if(event.target.value === '') {
    $('#plan-select').html('');
  } else {
    networksByPlan = JSON.parse(event.target.getAttribute("data-networksByPlan"))
    htmlString = networksByPlan[event.target.value]
        .map(network => `<option value="${network.reference}">${network.display}</option>`).join('\n');
        $('#network-select').html(htmlString);
        updateHealthcareServiceNetwork({ target: { value: $('#network-select').val() } });
  }
};

let HealthcareServiceParams = {};

const updateHealthcareServiceSearchParam = function(event, param) {
  HealthcareServiceParams[param] = event.target.value;
};

const updateHealthcareServiceNetwork = function (event) {
  updateHealthcareServiceSearchParam(event, 'network');
};

const updateHealthcareServiceType = function (event) {
  updateHealthcareServiceSearchParam(event, 'type');
}

const updateHealthcareServiceCategory = function (event) {
  updateHealthcareServiceSearchParam(event, 'category');
}

const updateHealthcareServiceSpecialty = function (event) {
  updateHealthcareServiceSearchParam(event, 'specialty');
}

const updateHealthcareServiceZip = function (event) {
  updateHealthcareServiceSearchParam(event, 'zip');
};
const updateHealthcareServiceRadius = function (event) {
  updateHealthcareServiceSearchParam(event, 'radius');
};

const updateHealthcareServiceCity= function (event) {
  updateHealthcareServiceSearchParam(event, 'city');
};

const updateHealthcareServiceName = function (event) {
  updateHealthcareServiceSearchParam(event, 'name');
};

const submitHealthcareServiceSearch = function (_event) {
  const params = Object.entries(HealthcareServiceParams)
        .filter(([key, value]) => value && value.length > 0)
        .map(([key, value]) => `${key}=${value}`)
        .join(`&`);

  console.log(params);
  fetchHealthcareServices(params);
};

const fetchHealthcareServices = function (params) {
  fetch(`/healthcare_services/search.json?${params}`)
    .then(response => response.json())
    .then(response => 
      {
        const { healthcare_services, nextPage, previousPage, searchParams } = response;
        updateHealthcareServices(healthcare_services);
        updateHealthcareServiceNavigationButtons(nextPage, previousPage);
        updateHealthcareServiceQuery(searchParams);
      }
    );
};

const updateHealthcareServices = function (healthcare_services) {
  const rows = HealthcareServiceRows(healthcare_services);
  $('#healthcare-services-table').html(rows);
};

const updateHealthcareServiceNavigationButtons = function (nextPage, previousPage) {
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
  updateHealthcareServiceNavigationActions(hasNextPage, hasPreviousPage);
};

const updateHealthcareServiceNavigationActions = function (hasNextPage, hasPreviousPage) {
  $('#next-button').off('click');
  $('#previous-button').off('click');
  if (hasNextPage) {
    $('#next-button').on('click', () => fetchHealthcareServices('page=next'));
  }
  if (hasPreviousPage) {
    $('#previous-button').on('click', () => fetchHealthcareServices('page=previous'));
  }
};

const HealthcareServiceHeaderRow = `
  <tr>
    <th>Name</th>
    <th>Type</th>
    <th>Provided By</th>
    <th>Categories</th>
    <th>Specialties</th>
    <th>Locations</th>
    <th>Phone/Fax</th>
    <th>Coverage Areas</th>
    <th>Service Provision Codes</th>
    <th>Eligibilities</th>
    <th>Programs</th>
    <th>Chararacteristics</th>
    <th>Communications</th>
    <th>Referral Methods</th>
    <th>Available Times</th>
    <th>Not Availables</th>
    <th>Availability Exceptions</th>
    <th>Endpoints</th>
  </tr>
`;

const HealthcareServiceRows = function (healthcare_services) {
  if (healthcare_services.length > 0) {
    return HealthcareServiceHeaderRow + healthcare_services.map(healthcareService => {
      return `
          <tr>
            <td>
              <a href="/locations/${healthcareService.id}">
                ${healthcareService.name}
              </a>
            </td>
            <td>${healthcareService.type}</td>
            <td>${healthcareService.provided_by}</td>
            <td>${healthcareService.categories}</td>
            <td>${healthcareService.specialties}</td>
            <td>${healthcareService.locations}</td>
            <td>${healthcareService.telecom.join('<br>')}</td>
            <td>${healthcareService.coverage_areas}</td>
            <td>${healthcareService.service_provision_codes}</td>
            <td>${healthcareService.eligibilities}</td>
            <td>${healthcareService.programs}</td>
            <td>${healthcareService.characteristics}</td>
            <td>${healthcareService.communications}</td>
            <td>${healthcareService.referral_methods}</td>
            <td>${healthcareService.available_times}</td>
            <td>${healthcareService.not_availables}</td>
            <td>${healthcareService.availability_exceptions}</td>
            <td>${healthcareService.endpoints}</td>
          </tr>
        `;
    }).join('');
  } else {
    return `
      <tr>
        <th>No healthcare services found</th>
      </tr>
    `;
  }
};

const updateHealthcareServiceQuery = function (query){
  content = HealthcareServiceQuery(query);
  $('#healthcare-service-query').html(content)
};

const HealthcareServiceQuery = function (query) {
  if(query.length > 0){
    return `
      <p>Query to server</p>
      <p class="query">
        ${query}
      </p>
    `;
  }
};
 