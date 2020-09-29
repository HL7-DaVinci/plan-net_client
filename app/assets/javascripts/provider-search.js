$(() => {
  updateProviderNetworkSelectionByPlan();
});

const updateProviderNetworkSelectionByPlan = function () {
  networks = $('#provider_network').html();

  $('#provider_insurance_plan').change(function() {
    plan = $('#provider_insurance_plan :selected').val();
    options = $(networks).filter("optgroup[label='" + plan + "']").html();
    if (options) {
      $('#provider_network').html(options);
    } else {
      $('#provider_network').empty();
    }
  });
}
 