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
// ***** {{data['name']}}::{{device}} ************** BEGIN *** .items

  String {{data['name']}}_name "Device name: [%s]" (gNames) { mqtt="<[nasmqtt:homie/{{device}}/$name:state:REGEX((.*))]" }
  Switch {{data['name']}}_online "Device online: [%s]" (gReachable) { mqtt="<[nasmqtt:homie/{{device}}/$online:state:JS(homie-tf.js)"}
  % sitemap = 'Text item=' + data['name'] + '_online icon="switch" visibility=[' + data['name'] + '_online==OFF]\n'
  % additional_config = ''
  %for key in sorted(sensor):
    %if key.endswith('/$type'):
      %if sensor[key] == 'blinds':
  Rollershutter {{data['name']}}_{{key.replace('/$type','')}} "{{data['name']}}->{{sensor[key]}}->{{key.replace('/$type','')}}" (g{{sensor[key]}}, gHomieSensors) [ "Lighting" ] {
    mqtt="
      >[nasmqtt:homie/{{device}}/{{key.replace('/$type','')}}/position/set:command:*:default],
      <[nasmqtt:homie/{{device}}/{{key.replace('/$type','')}}/position:state:default]
      "
  }
  % sitemap += 'Default item=' + data['name'] + '_' + key.replace('/$type','') + ' label="' + data['name'] + '->' + sensor[key] + '->' + key.replace('/$type','') + '" visibility=[' + data['name'] + '_online==ON]\n\n'
  % additional_config += '  Slider item=' + data['name'] + '_' + key.replace('/$type','') + '\n'
      %elif sensor[key] == 'button':
  String {{data['name']}}_{{key.replace('/$type','')}} "{{data['name']}}->{{sensor[key]}}->{{key.replace('/$type','')}}" (g{{sensor[key]}}, gHomieSensors) {
    mqtt="<[nasmqtt:homie/{{device}}/{{key.replace('/$type','')}}/event:state:default]"
  }
      %else:
  //!!! UNKNOWN SENSOR TYPE: {{sensor[key]}} YOU ARE ON YOUR OWN
  String {{data['name']}}_{{key.replace('/$type','')}} "{{data['name']}}->{{sensor[key]}}->{{key.replace('/$type','')}}" (g{{sensor[key]}}, gHomieSensors) {
    mqtt="<[nasmqtt:homie/{{device}}/{{key.replace('/$type','')}}/event:state:default]"
  }
      %end
    %end
  %end
  % sitemap += 'Text item=' + data['name'] +' label="' + data['name'] + ' config " icon="settings" visibility=[' + data['name'] +'_online==ON] {\n'
  % sitemap += additional_config
  % if 'settings' in config:
    %for setting in sorted (config['settings']):
      %if type(config['settings'][setting]) == int:
      Number {{data['name']}}_setting_{{setting}} "{{data['name']}}->settings->{{setting}}: [%s]" (gHomieSettings) {
        mqtt="
            <[nasmqtt:homie/{{device}}/$implementation/config:state:JSONPATH($.settings.{{setting}})],
            >[nasmqtt:homie/{{device}}/$implementation/config/set:command:*:JS(homie-settings-{{setting}}.js)]
        "
      }
      % sitemap += '  Setpoint item=' + data['name'] + '_setting_' + setting + ' //minValue=1000 maxValue=60000 step=500\n'
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
      % sitemap += '  Switch item=' + data['name'] + '_setting_' + setting + ' \n'
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
  %end
  % sitemap += '}\n'

// ***** {{data['name']}}::{{device}} ************** END *** .items

// ***** {{data['name']}}::{{device}} ************** BEGIN *** .sitemap

{{sitemap}}

// ***** {{data['name']}}::{{device}} ************** END *** .sitemap

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
