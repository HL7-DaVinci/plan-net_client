$(() => {
  if ($('#payer-select').length > 0) {
    updateNetworkList({ target: { value: $('#payer-select').val() } });
  }
});

const updateNetworkList = function (event) {
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
      });
  }
};
