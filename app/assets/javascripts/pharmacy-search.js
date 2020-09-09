$(() => {
  update_pharmacy_network_selection_by_plan();
});

const update_pharmacy_network_selection_by_plan = function () {
  networks = $('#pharmacy_network').html();

  $('#pharmacy_insurance_plan').change(function() {
    plan = $('#pharmacy_insurance_plan :selected').val();
    options = $(networks).filter("optgroup[label='" + plan + "']").html();
    if (options) {
      $('#pharmacy_network').html(options);
    } else {
      $('#pharmacy_network').empty();
    }
  });
}
