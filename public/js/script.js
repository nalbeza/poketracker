    var map, heatmap, data;

    function initMap() {
      data = new google.maps.MVCArray()
      map = new google.maps.Map(document.getElementById('map'), {
        zoom: 13,
        center: { lat: 48.856614, lng: 2.352222 },
        mapTypeId: google.maps.MapTypeId.ROADMAP
      });

      heatmap = new google.maps.visualization.HeatmapLayer({
        data: data,
        map: map,
        raduis: 20,
        opacity: 1.0
      });
    }

    function loadPoints() {
      var req = new XMLHttpRequest;
      var name = document.getElementById('pokename').value.toUpperCase();

      req.overrideMimeType("application/json");
      req.open('GET', 'http://localhost:4567/data?name=' + name);
      req.onload = function() {
        if (req.status == 200) {
          var json = JSON.parse(req.responseText);
          data.clear();
          json.data.forEach(function(e) {
            latlng = new google.maps.LatLng(e.latitude, e.longitude)
            data.push({ location: latlng, weight: e.count });
          });
        }
      };
      req.send();

      return [
        new google.maps.LatLng(37.751266, -122.403355)
      ];
    }


    function capitalizeFirstLetter(string) {
      return string.charAt(0).toUpperCase() + string.slice(1);
    }

    $(function() {

      $.getJSON("data/pokemon-list.json", function(data) {
        console.log("Data", data);

        pokemons = data.pokemons.map(function(pokemon) {
          return {
            api_id: pokemon.api_id,
            value: pokemon.name,
            image_url: pokemon.image_url,
          };
        });

        $(".pokename").autocomplete({
            minLength: 1,
            source: pokemons,
            select: function(event, ui) {
              // var img = $("<img>").prop("src", ui.item.image_url);

              event.target.value = capitalizeFirstLetter(ui.item.value);
              $('#search_form').submit();
              return false;
            }
          })
          .autocomplete("instance")._renderItem = function(ul, item) {
            return $("<li>")
              .append('<div class="cnt"><img src="' + item.image_url + '" alt="' + item.value + '" />' + item.value + '</div>')
              .appendTo(ul);
          };

        console.log($("#search_form"));

        $('#search_form').submit(function() {
          loadPoints();
          return false;
        })

        // $(".pokename").autocomplete({
        //   source: function(request, response) {
        //     $.ajax({
        //       url: "data/pokemon-list.json",
        //       dataType: "jsonp",
        //       data: {
        //         q: request.term
        //       },
        //       success: function(data) {

        //         // Handle 'no match' indicated by [ "" ] response
        //         response(data.length === 1 && data[0].length === 0 ? [] : data);
        //       }
        //     });
        //   },
        //   minLength: 3,
        //   select: function(event, ui) {
        //     log("Selected: " + ui.item.label);
        //   }
        // });
      });
    });