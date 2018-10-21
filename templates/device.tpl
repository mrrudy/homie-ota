<!DOCTYPE html>
<html>
<head>
  <title>Homie device - {{device}}</title>
  <meta http-equiv="refresh" content="60" />
  <script type="text/javascript" src="{{base_url}}/jquery.min.js"></script>
  <link rel="stylesheet" href="{{base_url}}/styles.css">
  </head>
<body>
<h2>Homie device details</h2>

<p>
[<a href="{{base_url}}/">Homie device inventory</a>] [<a href="{{base_url}}/log">Log</a>] [<a class="delete" data-delete-url="{{base_url}}/device/{{device}}" href="#">Delete</a>]
</p>

<h3>Details for device {{device}}</h3>
<table border="1">
<thead>
<tr>
  <th>key</th><th>value</th>
</tr>
</thead>
%for item in sorted(data):
<tr>
  <td class="detailkey">{{item}}</td>
  <td class="detailvalue">{{ data[item] }}</td>
</tr>
%end
</table>

<h3>Sensor data for device {{device}}</h3>
<table border="1">
<thead>
<tr>
  <th>key</th><th>value</th>
</tr>
</thead>
%for key in sorted(sensor):
<tr>
  <td class="detailkey">{{key}}</td>
  <td class="detailvalue">{{ sensor[key] }}</td>
</tr>
%end
</table>
<h3>OpenHab config</h3>
%import json
%config = json.loads(sensor['$implementation/config'])
<pre><code>
// ***** {{data['name']}}::{{device}} ************** BEGIN 

  String {{data['name']}}_name "Device name: [%s]" (gNames) { mqtt="<[nasmqtt:homie/{{device}}/$name:state:REGEX((.*))]" }
  Switch {{data['name']}}_online "Device online: [%s]" (gReachable) { mqtt="<[nasmqtt:homie/{{device}}/$online:state:JS(homie-tf.js)"}

  %for key in sorted(sensor):
    %if key.endswith('/$type'):
      %if sensor[key] == 'blinds':
  Rollershutter {{data['name']}}_{{key.replace('/$type','')}} "{{data['name']}}->{{sensor[key]}}->{{key.replace('/$type','')}}" (g{{sensor[key]}}, gHomieSensors) {
    mqtt="
      >[nasmqtt:homie/{{device}}/{{key.replace('/$type','')}}/position/set:command:*:default],
      <[nasmqtt:homie/{{device}}/{{key.replace('/$type','')}}/position:state:default]
      "
  }
      %elif sensor[key] == 'button':
  String {{data['name']}}_{{key.replace('/$type','')}} "{{data['name']}}->{{sensor[key]}}->{{key.replace('/$type','')}}" (g{{sensor[key]}}, gHomieSensors) {
    mqtt="<[nasmqtt:homie/{{device}}/{{key.replace('/$type','')}}/event:state:default]"
  }
      %else:
  //!!! UNKNOWS SENSOR TYPE: {{sensor[key]}} YOU ARE ON YOUR OWN
  String {{data['name']}}_{{key.replace('/$type','')}} "{{data['name']}}->{{sensor[key]}}->{{key.replace('/$type','')}}" (g{{sensor[key]}}, gHomieSensors) {
    mqtt="<[nasmqtt:homie/{{device}}/{{key.replace('/$type','')}}/event:state:default]"
  }
      %end
    %end
  %end
  %for setting in sorted (config['settings']):
    %if type(config['settings'][setting]) == int:
    Number {{data['name']}}_setting_{{setting}} "{{data['name']}}->settings->{{setting}}: [%s]" (gHomieSettings) {
      mqtt="
          <[nasmqtt:homie/{{device}}/$implementation/config:state:JSONPATH($.settings.{{setting}})],
          >[nasmqtt:homie/{{device}}/$implementation/config/set:command:*:JS(homie-settings-{{setting}}.js)]
      "
    }
  /*********** TODO for U:
  cat >> /etc/openhab2/transform/homie-settings-{{setting}}.js
  result = '{"settings":{"{{setting}}":' + input + '}}';
  ************/

    %elif type(config['settings'][setting]) == bool:
    String {{data['name']}}_setting_{{setting}} "{{data['name']}}->settings->{{setting}}?" (gHomieSettings) {
      mqtt="
          <[nasmqtt:homie/{{device}}/$implementation/config:state:JS(homie-settings-{{setting}}-get.js)],
          >[nasmqtt:homie/{{device}}/$implementation/config/set:command:*:JS(homie-settings-{{setting}}.js)]
      "
    }
  /*********** TODO for U:
  cat >> /etc/openhab2/transform/homie-settings-{{setting}}.js
  result = '{"settings":{"{{setting}}":' + ((input == "ON") ? "true" : "false") + '}}';

  cat >> /etc/openhab2/transform/homie-settings-{{setting}}-get.js
  result = ((JSON.parse(input)["settings"]["{{setting}}"]) == true ? "ON" : "OFF");
  ************/

    %else:
  //  conf(string):: {{setting}}:: {{config['settings'][setting]}}
    %end
  %end

// ***** {{data['name']}}::{{device}} ************** END
</code></pre>
<script type="application/javascript">
$('.delete').bind('click', function (e){
  e.preventDefault();
  if (confirm("Are you sure to delete this device?")) {
    $.ajax({
      url: $(this).data('delete-url'),
      type: 'DELETE',
      async: true
    })
    .done(function() {
      alert('Deleted device');
      window.location.href = '{{base_url}}/';
    })
    .fail(function(e) {
      alert('Error: ' + e.statusText);
    })
  }
  return false;
})
</script>
</body>
</html>
