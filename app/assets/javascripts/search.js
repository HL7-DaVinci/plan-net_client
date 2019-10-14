const updateQueryString = function (event) {
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

  if (event && event.key === 'Enter') {
    $('#search-button').click();
  }
};

let searchField;
const getSearchField = function () {
  if (!searchField) {
    searchField = $('#search-params > div').first().clone();
    searchField.children('div > div').prepend(
      '<button class="btn btn-outline-secondary" type="button" onclick="removeSearchField(event)">-</button>'
    );
    searchField.children('div > input')[0].value = '';
  }
};

const addSearchField = function (_event) {
  $('#search-params').append(searchField.clone());
};

const removeSearchField = function(event) {
  $(event.target).parent().parent().remove();
  updateQueryString();
};

const loadQueriesFromUrl = function () {
  const queryString = new URLSearchParams(window.location.search).get('query_string');
  if (queryString) {
    const queries = new URLSearchParams(queryString);
    for (const [query, value] of queries) {
      $('#search-params > div').last().children('select')[0].value = query;
      $('#search-params > div').last().children('input')[0].value = value;
      addSearchField();
    }
  }
};

$(() => {
  if ($('#search-params').length > 0) {
    getSearchField();
    loadQueriesFromUrl();
    updateQueryString();
  }
});
