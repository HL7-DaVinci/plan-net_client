$(() => {
  update_network_selection_by_plan();
});

const update_network_selection_by_plan = function () {
  networks = $('#healthcare_service_network').html();

  $('#healthcare_service_insurance_plan').change(function() {
    plan = $('#healthcare_service_insurance_plan :selected').val();
    options = $(networks).filter("optgroup[label='" + plan + "']").html();
    if (options) {
      $('#healthcare_service_network').html(options);
    } else {
      $('#healthcare_service_network').empty();
    }
  });
}