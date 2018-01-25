%include('header_init.tpl', heading='Manage your qualitative attributes')

<br />
<br />

<h2 style="display:inline-block; margin-right: 40px;">Delete all attributes: </h2>
<button type="button" class="btn btn-default del_simu">Delete</button>

<h2>List of current attributes:</h2>
<table class="table">
    <thead>
        <tr>
            <th style='width:50px;'>State</th>
            <th>Attribute name</th>
            <th>Values</th>
            <th>Method</th>
            <th>Edit</th>
            <th><img src='/static/img/delete.ico' style='width:16px;' class="del_simu" /></th>
        </tr>
    </thead>
    <tbody id="table_attributes">
    </tbody>
</table>

<br /><br />

<div id="add_attribute">
    <h2> Add a new qualitative attribute: </h2>

    <div class="form-group">
        <label for="att_name">Name :</label>
        <input type="text" class="form-control" id="att_name" placeholder="Name">
    </div>

    <div class="form-group">
        <label for="att_value_worst">Least prefered value:</label>
        <input type="text" class="form-control" id="att_value_worst" placeholder="Worst value">
    </div>
	
	<div class="form-group">
        <label for="att_value_med">Medium value(s):</label>
			<input type="button" class="btn btn-default" id="add_value_med" value="Add an item"/>   
			<input type="button" class="btn btn-default" id="del_value_med" value="Delete last item"/>
			<ol id="list_med_values">
				<li><input type="text" class="form-control" id="att_value_med_1" placeholder='Value Med 1'/></li>
			</ol>
    </div>
	
    <div class="form-group">
        <label for="att_value_best">Most prefered value:</label>
        <input type="text" class="form-control" id="att_value_best" placeholder="Best value">
    </div>
	
    <div class="form-group">
        <label for="att_method">Method: (for now, it's always forced to PE)</label>
        <select class="form-control" id="att_method">
          <option value="PE">Probability Equivalence</option>
          <option value="CE_Constant_Prob">Certainty Equivalence - Constant Probability</option>
		  <option value="CE_Variable_Prob">Certainty Equivalence - Variable Probability</option>
          <option value="LE">Lottery Equivalence</option>
        </select>
    </div>
	
    <button type="submit" class="btn btn-default" id="submit">Submit</button>

</div>


%include('js.tpl')




<script>

// Fonctions pour ajouter/supprimer des zones de texte pour les valeurs intermédiaires
var list_med_values = document.getElementById('list_med_values'),
	lists = list_med_values.getElementsByTagName('li'),
	add_value_med = document.getElementById('add_value_med'),
	del_value_med = document.getElementById('del_value_med');

add_value_med.addEventListener('click', function() {
	var longueur = lists.length;
	var new_item = document.createElement('li');
	new_item.innerHTML = "<input type='text' class='form-control' id='att_value_med_"+ String(longueur+1) +"' placeholder='Value Med " + String(longueur+1) +"'/>";
	lists[longueur-1].parentNode.appendChild(new_item);
});

del_value_med.addEventListener('click', function() {
	var longueur = lists.length;
	if (longueur!=1){
		lists[longueur-1].parentNode.removeChild(lists[longueur-1]);
	} else {
		alert("Please put at least one medium value for the attribute "+$('#att_name').val());
	};
});





    $(function() {

        $('#edit_attribute').hide();

        $('.del_simu').click(function() {
            if (confirm("Are you sure ?") == false) {
                return
            };
            localStorage.removeItem("assess_session_QUALI");
            window.location.reload();
        });
        $('li.manage_quali').addClass("active");

        var assess_session_QUALI = JSON.parse(localStorage.getItem("assess_session_QUALI"));
        var edit_mode = false;
        var edited_attribute=0;

        if (!assess_session_QUALI) {
            assess_session_QUALI = {
                "attributes": [],
                "k_calculus": [{
                    "method": "multiplicative",
                    "active": "false",
                    "k": [],
                    "GK": null,
                    "GU": null
                }, {
                    "method": "multilinear",
                    "active": "false",
                    "k": [],
                    "GK": null,
                    "GU": null
                }],
                "settings": {
                    "decimals_equations": 3,
                    "decimals_dpl": 8,
                    "proba_ce": 0.3,
                    "proba_le": 0.3,
                    "language": "english",
                    "display": "trees"
                }
            };
            localStorage.setItem("assess_session_QUALI", JSON.stringify(assess_session_QUALI));
        }

        function isAttribute(name) {
            for (var i = 0; i < assess_session_QUALI.attributes.length; i++) {
                if (assess_session_QUALI.attributes[i].name == name) {
                    return true;
                }
            }
            return false;
        }
		
		function isOneValueOfTheListEmpty(val_list){
			var list_len = val_list.length;
			for (var i=0; i<list_len; i++) {
				if(val_list[i] == ""){return true}
			};
			return false;
		};
		
		function areAllValuesDifferent(val_list, val_min, val_max){
			var list_len = val_list.length;
			for (var i=0; i<list_len; i++) {
				if (val_list[i] == val_min || val_list[i] == val_max){
					return false;
				};
				for (var j=0; j<list_len; j++) {
					if(val_list[i] == val_list[j] && i!=j){
						return false;
					}
				}
			};
			return true;
		};
		
		

        function checked_button_clicked(element) {
            var checked = $(element).prop("checked");
            var i = $(element).val();

            //we modify the propriety
            var assess_session_QUALI = JSON.parse(localStorage.getItem("assess_session_QUALI"));
            assess_session_QUALI.attributes[i].checked = checked;

            //we update the assess_session_QUALI storage
            localStorage.setItem("assess_session_QUALI", JSON.stringify(assess_session_QUALI));
        }

        function sync_table() {
            $('#table_attributes').empty();
            if (assess_session_QUALI) {
                for (var i = 0; i < assess_session_QUALI.attributes.length; i++) {
                    var attribute = assess_session_QUALI.attributes[i];
                    var text_table = "<tr>";
                    
					if (attribute.checked)
                        text_table += '<td><input type="checkbox" id="checkbox_' + i + '" value="' + i + '" name="' + attribute.name + '" checked></td>';
                    else
                        text_table += '<td><input type="checkbox" id="checkbox_' + i + '" value="' + i + '" name="' + attribute.name + '" ></td>';


                    text_table += '<td>' + attribute.name + '</td>' +
								  '<td><ul><li>' + attribute.val_worst + '</li>';
								  
					for (var ii=0, len=attribute.val_med.length; ii<len; ii++){
						text_table += '<li>' + attribute.val_med[ii] + '</li>';
					};
						
					text_table += '<li>' + attribute.val_best + '</li></td>'+
								  '<td>' + attribute.method + '</td>';
								  
                    text_table += '<td><button type="button" id="edit_' + i + '" class="btn btn-default btn-xs">Edit</button></td>'+
								  '<td><img id="deleteK' + i + '" src="/static/img/delete.ico" style="width:16px;"/></td></tr>';

                    $('#table_attributes').append(text_table);

                    //we will define the action when we click on the check input
                    $('#checkbox_' + i).click(function() {
                        checked_button_clicked($(this))
                    });

                    (function(_i) {
                        $('#deleteK' + _i).click(function() {
                            if (confirm("Are you sure ?") == false) {
                                return
                            };
                            assess_session_QUALI.attributes.splice(_i, 1);
                            // backup local
                            localStorage.setItem("assess_session_QUALI", JSON.stringify(assess_session_QUALI));
                            //refresh the page
                            window.location.reload();
                        });
                    })(i);

                    (function(_i) {
						$('#edit_' + _i).click(function() {
							edit_mode=true;
							edited_attribute=_i;
							var attribute_edit = assess_session_QUALI.attributes[_i];
							$('#add_attribute h2').text("Edit attribute "+attribute_edit.name);
							$('#att_name').val(attribute_edit.name);
							$('#att_value_worst').val(attribute_edit.val_worst);
							$('#att_value_med_1').val(attribute_edit.val_med[0]);
							
							for (var ii=2, len=attribute_edit.val_med.length; ii<len+1; ii++) {
								var longueur = lists.length;
								var new_item = document.createElement('li');
								new_item.innerHTML = "<input type='text' class='form-control' id='att_value_med_"+ String(longueur+1) +"' placeholder='Value Med " + String(longueur+1) +"'/>";
								lists[longueur-1].parentNode.appendChild(new_item);
								
								$('#att_value_med_'+ii).val(attribute_edit.val_med[ii-1]);
							};
							
							$('#att_value_best').val(attribute_edit.val_best);
							$('#att_method option[value='+attribute_edit.method+']').prop('selected', true);
						});
                    })(i);
                }

            }
        }
        sync_table();

        $('#submit').click(function() {
            var name = $('#att_name').val(),
				val_worst = $('#att_value_worst').val(),
				nb_med_values = document.getElementById('list_med_values').getElementsByTagName('li').length,
				val_med = [],
				val_best = $('#att_value_best').val();
				
			for (var ii=1; ii<nb_med_values+1; ii++){
				val_med.push($('#att_value_med_'+ii).val());
			};

            var method = "PE";
            <!-- if ($("select option:selected").text() == "Probability Equivalence") { -->
                <!-- method = "PE"; -->
            <!-- } else if ($("select option:selected").text() == "Lottery Equivalence") { -->
                <!-- method = "LE"; -->
            <!-- } else if ($("select option:selected").text() == "Certainty Equivalence - Constant Probability") { -->
                <!-- method = "CE_Constant_Prob"; -->
            <!-- } else if ($("select option:selected").text() == "Certainty Equivalence - Variable Probability") { -->
                <!-- method = "CE_Variable_Prob"; -->
            <!-- } -->

            
            if (name=="" || val_worst=="" || val_best=="") {
                alert('Please fill correctly all the fields');
            }
            else if (isAttribute(name) && (edit_mode == false)) {
				alert ("An attribute with the same name already exists");
            } else if (isOneValueOfTheListEmpty(val_med)) {
				alert("One of your medium values is empty");
			} else if (val_worst==val_best) {
				alert("The least prefered and most prefered values are the same");
			} else if (areAllValuesDifferent(val_med, val_worst, val_best)==false) {
				alert("At least one of the values is appearing more than once");
			}

            else {
				if (edit_mode==false) {
					assess_session_QUALI.attributes.push({
						"name": name,
						'val_worst': val_worst,
						'val_med': val_med,
						'val_best': val_best,
						'method': method,
						'completed': 'False',
						'checked': true,
						'questionnaire': {
							'number': 0,
							'points': {},//{'val_worst' : [0, -1], 'val_best' : [1, -2]},
							'utility': {}
						}
					});
				} else {
					if (confirm("Are you sure you want to edit this attribute? All assessements will be deleted") == true) {
						assess_session_QUALI.attributes[edited_attribute]={
							"name": name,
							'val_worst': val_worst,
							'val_med': val_med,
							'val_best': val_best,
							'method': method,
							'completed': 'False',
							'checked': true,
							'questionnaire': {
								'number': 0,
								'points': {},
								'utility': {}
							}
						};
					}
					edit_mode=false;
					$('#add_attribute h2').text("Add a new attribute");
				}
				
                sync_table();
                localStorage.setItem("assess_session_QUALI", JSON.stringify(assess_session_QUALI));
				$('#att_name').val("");
				$('#att_value_worst').val("");
				$('#att_value_med_1').val("");
				$('#att_value_best').val("");
				
				for (var ii=val_med.length; ii>1; ii--) {
					var longueur = document.getElementById('list_med_values').getElementsByTagName('li').length;
					lists[longueur-1].parentNode.removeChild(lists[longueur-1]);
				};
            }


        });

    });
</script>
%include('header_end.tpl')
</body>

</html>
