const updateQueryString = function (_event) {
  let query='';
  $('#search-params > div').each(function () {
    let param = $(this).children('select')[0].value;
    let value = $(this).children('input')[0].value;

    if (value === '') {
      return;
    }
    if (query.length > 0) {
      query += '&';
    }
    query += `${param}=${value}`;
  });
  $('#search-url').html(query);
  $('#query_string')[0].value = query;
};

const addSearchField = function (event) {
  const searchField = `
    <div class="input-group mb-3">
      <select class="custom-select" onchange="updateQueryString(event)">
        <option value="name">name</option>
        <option value="_id">id</option>
      </select>
      <input type="text" class="form-control bg-dark text-white" onkeyup="updateQueryString(event)">
      <div class="input-group-append">
        <button class="btn btn-outline-secondary" type="button" onclick="removeSearchField(event)">-</button>
        <button class="btn btn-outline-secondary" type="button" onclick="addSearchField(event)">+</button>
      </div>
    </div>
  `;
  $('#search-params').append(searchField);
  const addedField = $('#search-params > div').last();
};

const removeSearchField = function(event) {
  $(event.target).parent().parent().remove();
};

$(() => {
  updateQueryString();
});
