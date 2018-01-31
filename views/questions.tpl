%include('header_init.tpl', heading='Assess utility functions')
<h3 id="attribute_name"></h3>

<div id="select">
	<table class="table">
		<thead>
			<tr>
				<th>Attribute</th>
				<th>Type</th>
				<th>Method</th>
				<th>Number of assessed points</th>
				<th>Assess another point</th>
				<th>Display utility graph</th>
				<th>Reset assessements</th>
			</tr>
		</thead>
		<tbody id="table_attributes">
		</tbody>
	</table>
</div>

<div id="trees"></div>

<div id="charts">
	<h2>Select the regression function you want to use</h2>
</div>

<div id="main_graph" class="col-lg-5"></div>
<div id="functions" class="col-lg-7"></div>

%include('header_end.tpl')
%include('js.tpl')

<script>
	var tree_image = '{{ get_url("static", path="img/tree_choice.png") }}';
</script>

<!-- Tree object -->
<script src="{{ get_url('static', path='js/tree.js') }}"></script>

<script>
	$(function() {
		$('li.questions').addClass("active");
		$('#attribute_name').hide()
		$('#charts').hide();
		$('#main_graph').hide();
		$('#functions').hide();

		var assess_session = JSON.parse(localStorage.getItem("assess_session")),
			settings = assess_session.settings;

		// We fill the table of the existing attributes and assessments
		for (var i = 0; i < assess_session.attributes.length; i++) {
			if (!assess_session.attributes[i].checked) //if this attribute is not activated
				continue; //we skip this attribute and go to the next one
				
			var attribute = assess_session.attributes[i],
				text_table = '<tr><td>' + attribute.name + '</td>'+
							 '<td>' + attribute.type + '</td>'+
							 '<td>' + attribute.method + '</td>'+
							 '<td>' + attribute.questionnaire.number + '</td>';
							
			text_table += '<td><table style="width:100%"><tr><td>' + attribute.val_min + '</td><td> : </td><td>0</td></tr>';
			for (var ii=0, len=attribute.val_med.length; ii<len; ii++){
				text_table += '<tr><td>' + attribute.val_med[ii] + '</td><td> : </td>'; 
				if(attribute.questionnaire.points[attribute.val_med[ii]]){
					text_table += '<td>' + attribute.questionnaire.points[attribute.val_med[ii]] + '</td>';
				} else {
					text_table += '<td><button type="button" class="btn btn-default btn-xs answer_quest" id="q_' + attribute.name + '_' + attribute.val_med[ii] + '_' + ii + '">Assess</button>' + '</td></tr>';
				};
			}; 
			text_table += '<tr><td>' + attribute.val_max + '</td><td> : </td><td>1</td></tr></table></td>';

			if (attribute.questionnaire.number > 0) {
				text_table += '<td><button type="button" class="btn btn-default btn-xs calc_util" id="u_' + attribute.name + '">Utility function</button></td><td><button type="button" id="deleteK' + i + '" class="btn btn-default btn-xs">Reset</button></td>';
			} else {
				text_table += '<td>No assessment yet</td>';
			}

			$('#table_attributes').append(text_table);

			(function(_i) {
				$('#deleteK' + _i).click(function() {
					if (confirm("Are you sure you want to delete all the assessments for "+assess_session.attributes[_i].name+"?") == false) {
							return
					};
					assess_session.attributes[_i].questionnaire = {
							'number': 0,
							'points': {},
							'utility': {}
					};
					// backup local
					localStorage.setItem("assess_session", JSON.stringify(assess_session));
					//refresh the page
					window.location.reload();
				});
			})(i);
		}


		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////////////////////////// CLICK ON THE ANSWER BUTTON ////////////////////////////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

		$('.answer_quest').click(function() {
			// we store the name, value, and index of the attribute
			var question_id = $(this).attr('id').slice(2).split('_'),
				question_name = question_id[0],
				question_val = question_id[1],
				question_index = question_id[2];
				
			// we delete the slect div
			$('#select').hide();
			$('#attribute_name').show().html(question_name.toUpperCase());


			// which index is it ?
			var indice;
			for (var j = 0; j < assess_session.attributes.length; j++) {
				if (assess_session.attributes[j].name == question_name) {
					indice = j;
				}
			}

			var val_min = assess_session.attributes[indice].val_min,
				val_max = assess_session.attributes[indice].val_max,
				unit = assess_session.attributes[indice].unit,
				method = assess_session.attributes[indice].method,
				mode = assess_session.attributes[indice].mode;

			function random_proba(proba1, proba2) {
				var coin = Math.round(Math.random());
				if (coin == 1) {
					return proba1;
				} else {
					return proba2;
				}
			}

			//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			///////////////////////////////////////////////////////////////// PE METHOD ////////////////////////////////////////////////////////////////
			//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

			if (method == 'PE') {
				(function() {
					// VARIABLES
					var probability = 0.75,
						min_interval = 0,
						max_interval = 1,
						gain_certain = parseFloat(question_val);

					// INTERFACE
					var arbre_pe = new Arbre('pe', '#trees', settings.display, "PE");
					
					// SETUP ARBRE GAUCHE
					arbre_pe.questions_proba_haut = probability;
					arbre_pe.questions_val_max = (mode=="Normal"? val_max : val_min) + ' ' + unit;
					arbre_pe.questions_val_min = (mode=="Normal"? val_min : val_max) + ' ' + unit;
					arbre_pe.questions_val_mean = gain_certain + ' ' + unit;
					
					arbre_pe.display();
					arbre_pe.update();

					$('#trees').append('</div><div class=choice style="text-align: center;"><p>Which option do you prefer?</p><button type="button" class="btn btn-default" id="gain">Certain gain</button><button type="button" class="btn btn-default" id="lottery">Lottery</button></div>');

					// FUNCTIONS
					function sync_values() {
						arbre_pe.questions_proba_haut = probability;
						arbre_pe.update();
					}

					function treat_answer(data) {
						min_interval = data.interval[0];
						max_interval = data.interval[1];
						probability = parseFloat(data.proba).toFixed(2);

						if (max_interval - min_interval <= 0.05) {
							sync_values();
							ask_final_value(Math.round((max_interval + min_interval) * 100 / 2) / 100);
						} else {
							sync_values();
						}
					}

					function ask_final_value(val) {
						// we delete the choice div
						$('.choice').hide();
						$('.container-fluid').append(
							'<div id= "final_value" style="text-align: center;"><br /><br /><p>We are almost done. Please enter the probability that makes you indifferent between the two situations above. Your previous choices indicate that it should be between ' + min_interval + ' and ' + max_interval + ' but you are not constrained to that range <br /> ' + min_interval +
							'\
						 <= <input type="text" class="form-control" id="final_proba" placeholder="Probability" value="' + val + '" style="width: 100px; display: inline-block"> <= ' + max_interval +
							'</p><button type="button" class="btn btn-default final_validation">Validate</button></div>'
						);


						// when the user validate
						$('.final_validation').click(function() {
							var final_proba = parseFloat($('#final_proba').val());

							if (final_proba <= 1 && final_proba >= 0) {
								// we save it
								assess_session.attributes[indice].questionnaire.points[String(gain_certain)]=final_proba;
								assess_session.attributes[indice].questionnaire.number += 1;
								// backup local
								localStorage.setItem("assess_session", JSON.stringify(assess_session));
								// we reload the page
								window.location.reload();
							}
						});
					}

					sync_values();

					// HANDLE USERS ACTIONS
					$('#gain').click(function() {
						$.post('ajax', '{"type":"question", "method": "PE", "proba": ' + String(probability) + ', "min_interval": ' + min_interval + ', "max_interval": ' + max_interval + ' ,"choice": "0", "mode": "' + 'normal' + '"}', function(data) {
							treat_answer(data);
						});
					});

					$('#lottery').click(function() {
						$.post('ajax', '{"type":"question","method": "PE", "proba": ' + String(probability) + ', "min_interval": ' + min_interval + ', "max_interval": ' + max_interval + ' ,"choice": "1" , "mode": "' + 'normal' + '"}', function(data) {
							treat_answer(data);
						});
					});
				})()
			}

			//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			///////////////////////////////////////////////////////////////// LE METHOD ////////////////////////////////////////////////////////////////
			//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			else if (method == 'LE') {
				(function() {
					// VARIABLES
					var probability = random_proba(0.38, 0.13);
					var min_interval = 0;
					var max_interval = 0.5;

					// INTERFACE

					var arbre_le = new Arbre('gauche', '#trees', settings.display, "LE_left");
					var arbre_droite = new Arbre('droite', '#trees', settings.display, "LE_right");

					// SETUP ARBRE GAUCHE
					arbre_le.questions_proba_haut = probability;
					arbre_le.questions_val_max = val_max + ' ' + unit;
					arbre_le.questions_val_min = val_min + ' ' + unit;
					arbre_le.display();
					arbre_le.update();

					// SETUP ARBRE DROIT
					arbre_droite.questions_proba_haut = settings.proba_le;

					// The certain gain will change whether it is the 1st, 2nd or 3rd questionnaire
					if (assess_session.attributes[indice].questionnaire.number == 0) {
						arbre_droite.questions_val_max = parseFloat(val_min) + (parseFloat(val_max) - parseFloat(val_min)) / 2 + ' ' + unit;
					} else if (assess_session.attributes[indice].questionnaire.number == 1) {
						arbre_droite.questions_val_max = parseFloat(val_min) + (parseFloat(val_max) - parseFloat(val_min)) / 4 + ' ' + unit;
					} else if (assess_session.attributes[indice].questionnaire.number == 2) {
						arbre_droite.questions_val_max = parseFloat(val_min) + (parseFloat(val_max) - parseFloat(val_min)) * 3 / 4 + ' ' + unit;
					}

					arbre_droite.questions_val_min = val_min + ' ' + unit;
					arbre_droite.display();
					arbre_droite.update();

					// we add the choice button
					$('#trees').append('<div class=choice style="text-align: center;"><p>Which option do you prefer?</p><button type="button" class="btn btn-default lottery_a">Lottery A</button><button type="button" class="btn btn-default lottery_b">Lottery B</button></div>')


					function treat_answer(data) {
						min_interval = data.interval[0];
						max_interval = data.interval[1];
						probability = parseFloat(data.proba).toFixed(2);

						if (max_interval - min_interval <= 0.05) {
							arbre_le.questions_proba_haut = probability;
							arbre_le.update();
							ask_final_value(Math.round((max_interval + min_interval) * 100 / 2) / 100);
						} else {
							arbre_le.questions_proba_haut = probability;
							arbre_le.update();
						}
					}

					function ask_final_value(val) {
						$('.choice').hide();
						$('.container-fluid').append(
							'<div id= "final_value" style="text-align: center;"><br /><br /><p>We are almost done. Please enter the probability that makes you indifferent between the two situations above. Your previous choices indicate that it should be between ' + min_interval + ' and ' + max_interval + ' but you are not constrained to that range <br /> ' + min_interval +
							'\
						 <= <input type="text" class="form-control" id="final_proba" placeholder="Probability" value="' + val + '" style="width: 100px; display: inline-block"> <= ' + max_interval +
							'</p><button type="button" class="btn btn-default final_validation">Validate</button></div>'
						);

						// when the user validate
						$('.final_validation').click(function() {
							var final_proba = parseFloat($('#final_proba').val());

							if (final_proba <= 1 && final_proba >= 0) {
								// we save it
								assess_session.attributes[indice].questionnaire.points.push([parseFloat(arbre_droite.questions_val_max), final_proba * 2]);
								assess_session.attributes[indice].questionnaire.number += 1;
								// backup local
								localStorage.setItem("assess_session", JSON.stringify(assess_session));
								// we reload the page
								window.location.reload();
							}
						});
					}



					// HANDLE USERS ACTIONS
					$('.lottery_a').click(function() {
						$.post('ajax', '{"type":"question", "method": "LE", "proba": ' + String(probability) + ', "min_interval": ' + min_interval + ', "max_interval": ' + max_interval + ' ,"choice": "0" , "mode": "' + String(mode) + '"}', function(data) {
							treat_answer(data);
							console.log(data);
						});
					});

					$('.lottery_b').click(function() {
						$.post('ajax', '{"type":"question","method": "LE", "proba": ' + String(probability) + ', "min_interval": ' + min_interval + ', "max_interval": ' + max_interval + ' ,"choice": "1" , "mode": "' + String(mode) + '"}', function(data) {
							treat_answer(data);
							console.log(data);
						});
					});
				})()
			}

			//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			///////////////////////////////////////////////////////////////// CE METHOD ////////////////////////////////////////////////////////////////
			//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			else if (method == 'CE_Constant_Prob') {
				(function() {

					// VARIABLES
					if (assess_session.attributes[indice].questionnaire.number == 0) {
						var min_interval = val_min;
						var max_interval = val_max;
					} else if (assess_session.attributes[indice].questionnaire.number == 1) {
						var min_interval = assess_session.attributes[indice].questionnaire.points[0][0];
						var max_interval = val_max;
					} else if (assess_session.attributes[indice].questionnaire.number == 2) {
						var min_interval = val_min;
						var max_interval = assess_session.attributes[indice].questionnaire.points[0][0];
					}

					var L = [0.75 * (max_interval - min_interval) + min_interval, 0.25 * (max_interval - min_interval) + min_interval];
					var gain = Math.round(random_proba(L[0], L[1]));

					// INTERFACE

					var arbre_ce = new Arbre('ce', '#trees', settings.display, "CE");

					// SETUP ARBRE GAUCHE
					arbre_ce.questions_proba_haut = settings.proba_ce;
					arbre_ce.questions_val_max = max_interval + ' ' + unit;
					arbre_ce.questions_val_min = min_interval + ' ' + unit;
					arbre_ce.questions_val_mean = gain + ' ' + unit;
					arbre_ce.display();
					arbre_ce.update();

					// we add the choice button
					$('#trees').append('<div class=choice style="text-align: center;"><p>Which option do you prefer?</p><button type="button" class="btn btn-default" id="gain">Certain gain</button><button type="button" class="btn btn-default" id="lottery">Lottery</button></div>')

					function utility_finder(gain) {
						var points = assess_session.attributes[indice].questionnaire.points;
						if (gain == val_min) {
							if (mode == 'normal') {
								return 0;
							} else {
								return 1;
							}
						} else if (gain == val_max) {
							if (mode == 'normal') {
								return 1;
							} else {
								return 0;
							}
						} else {
							for (var i = 0; i < points.length; i++) {
								if (points[i][0] == gain) {
									return points[i][1];
								}
							}
						}
					}

					function treat_answer(data) {
						min_interval = data.interval[0];
						max_interval = data.interval[1];
						gain = data.gain;

						if (max_interval - min_interval <= 0.05 * parseFloat(arbre_ce.questions_val_max) - parseFloat(arbre_ce.questions_val_min) || max_interval - min_interval < 2) {
							$('.choice').hide();
							arbre_ce.questions_val_mean = gain + ' ' + unit;
							arbre_ce.update();
							ask_final_value(Math.round((max_interval + min_interval) * 100 / 2) / 100);
						} else {
							arbre_ce.questions_val_mean = gain + ' ' + unit;
							arbre_ce.update();
						}
					}

					function ask_final_value(val) {
						$('.lottery_a').hide();
						$('.lottery_b').hide();
						$('.container-fluid').append(
							'<div id= "final_value" style="text-align: center;"><br /><br /><p><p>We are almost done. Please enter the value that makes you indifferent between the two situations above. Your previous choices indicate that it should be between ' + min_interval + ' and ' + max_interval + ' but you are not constrained to that range <br /> ' + min_interval +
							'\
						 <= <input type="text" class="form-control" id="final_proba" placeholder="Probability" value="' + val + '" style="width: 100px; display: inline-block"> <= ' + max_interval +
							'</p><button type="button" class="btn btn-default final_validation">Validate</button></div>'
						);

						// when the user validate
						$('.final_validation').click(function() {
							var final_gain = parseInt($('#final_proba').val());
							var final_utility = arbre_ce.questions_proba_haut * utility_finder(parseFloat(arbre_ce.questions_val_max)) + (1 - arbre_ce.questions_proba_haut) * utility_finder(parseFloat(arbre_ce.questions_val_min));
							console.log(arbre_ce.questions_proba_haut);
							console.log(utility_finder(parseFloat(arbre_ce.questions_val_max)));
							console.log(utility_finder(parseFloat(arbre_ce.questions_val_min)));
							if (final_gain <= max_interval && final_gain >= min_interval) {
								// we save it
								assess_session.attributes[indice].questionnaire.points.push([final_gain, final_utility]);
								assess_session.attributes[indice].questionnaire.number += 1;
								// backup local
								localStorage.setItem("assess_session", JSON.stringify(assess_session));
								// we reload the page
								window.location.reload();
							}
						});
					}



					// HANDLE USERS ACTIONS
					$('#lottery').click(function() {
						$.post('ajax', '{"type":"question", "method": "CE_Constant_Prob", "gain": ' + String(gain) + ', "min_interval": ' + min_interval + ', "max_interval": ' + max_interval + ' ,"choice": "0" , "mode": "' + String(mode) + '"}', function(data) {
							treat_answer(data);
							console.log(data);
						});
					});

					$('#gain').click(function() {
						$.post('ajax', '{"type":"question","method": "CE_Constant_Prob", "gain": ' + String(gain) + ', "min_interval": ' + min_interval + ', "max_interval": ' + max_interval + ' ,"choice": "1" , "mode": "' + String(mode) + '"}', function(data) {
							treat_answer(data);
							console.log(data);
						});
					});
				})()
			}

			//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			///////////////////////////////////////////////////////////////// CEPV METHOD ////////////////////////////////////////////////////////////////
			//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
			else if (method == 'CE_Variable_Prob') {
				(function() {

					// VARIABLES
					if (assess_session.attributes[indice].questionnaire.number == 0) {
						var min_interval = val_min;
						var max_interval = val_max;
						p = 0.5;
					} else if (assess_session.attributes[indice].questionnaire.number == 1) {
						var min_interval = assess_session.attributes[indice].questionnaire.points[0][0];
						var max_interval = val_max;
						p = 0.25;
					} else if (assess_session.attributes[indice].questionnaire.number == 2) {
						var min_interval = val_min;
						var max_interval = assess_session.attributes[indice].questionnaire.points[0][0];
						p = 0.75;
					}

					var L = [0.75 * (max_interval - min_interval) + min_interval, 0.25 * (max_interval - min_interval) + min_interval];
					var gain = Math.round(random_proba(L[0], L[1]));

					// INTERFACE

					var arbre_cepv = new Arbre('cepv', '#trees', settings.display, "CE_PV");

					// SETUP ARBRE GAUCHE
					arbre_cepv.questions_proba_haut = p;
					arbre_cepv.questions_val_max = max_interval + ' ' + unit;
					arbre_cepv.questions_val_min = min_interval + ' ' + unit;
					arbre_cepv.questions_val_mean = gain + ' ' + unit;
					arbre_cepv.display();
					arbre_cepv.update();

					// we add the choice button
					$('#trees').append('<button type="button" class="btn btn-default" id="gain">Certain gain</button><button type="button" class="btn btn-default" id="lottery">Lottery</button>')

					function utility_finder(gain) {
						var points = assess_session.attributes[indice].questionnaire.points;
						if (gain == val_min) {
							if (mode == 'normal') {
								return 0;
							} else {
								return 1;
							}
						} else if (gain == val_max) {
							if (mode == 'normal') {
								return 1;
							} else {
								return 0;
							}
						} else {
							for (var i = 0; i < points.length; i++) {
								if (points[i][0] == gain) {
									return points[i][1];
								}
							}
						}
					}

					function treat_answer(data) {
						min_interval = data.interval[0];
						max_interval = data.interval[1];
						gain = data.gain;

						if (max_interval - min_interval <= 0.05 * parseFloat(arbre_cepv.questions_val_max) - parseFloat(arbre_cepv.questions_val_min) || max_interval - min_interval < 2) {
							$('#gain').hide();
							$('#lottery').hide();
							arbre_cepv.questions_val_mean = gain + ' ' + unit;
							arbre_cepv.update();
							ask_final_value(Math.round((max_interval + min_interval) * 100 / 2) / 100);
						} else {
							arbre_cepv.questions_val_mean = gain + ' ' + unit;
							arbre_cepv.update();
						}
					}

					function ask_final_value(val) {
						$('.lottery_a').hide();
						$('.lottery_b').hide();
						$('.container-fluid').append(
							'<div id= "final_value" style="text-align: center;"><br /><br /><p>We are almost done, please now enter the value of the gain: <br /> ' + min_interval +
							'\
						 <= <input type="text" class="form-control" id="final_proba" placeholder="Probability" value="' + val + '" style="width: 100px; display: inline-block"> <= ' + max_interval +
							'</p><button type="button" class="btn btn-default final_validation">Validate</button></div>'
						);

						// when the user validate
						$('.final_validation').click(function() {
							var final_gain = parseInt($('#final_proba').val());
							var final_utility = arbre_cepv.questions_proba_haut * utility_finder(parseFloat(arbre_cepv.questions_val_max)) + (1 - arbre_cepv.questions_proba_haut) * utility_finder(parseFloat(arbre_cepv.questions_val_min));
							console.log(arbre_cepv.questions_proba_haut);
							console.log(utility_finder(parseFloat(arbre_cepv.questions_val_max)));
							console.log(utility_finder(parseFloat(arbre_cepv.questions_val_min)));
							if (final_gain <= max_interval && final_gain >= min_interval) {
								// we save it
								assess_session.attributes[indice].questionnaire.points.push([final_gain, final_utility]);
								assess_session.attributes[indice].questionnaire.number += 1;
								// backup local
								localStorage.setItem("assess_session", JSON.stringify(assess_session));
								// we reload the page
								window.location.reload();
							}
						});
					}



					// HANDLE USERS ACTIONS
					$('#lottery').click(function() {
						$.post('ajax', '{"type":"question", "method": "CE_Constant_Prob", "gain": ' + String(gain) + ', "min_interval": ' + min_interval + ', "max_interval": ' + max_interval + ' ,"choice": "0" , "mode": "' + String(mode) + '"}', function(data) {
							treat_answer(data);
							console.log(data);
						});
					});

					$('#gain').click(function() {
						$.post('ajax', '{"type":"question","method": "CE_Constant_Prob", "gain": ' + String(gain) + ', "min_interval": ' + min_interval + ', "max_interval": ' + max_interval + ' ,"choice": "1" , "mode": "' + String(mode) + '"}', function(data) {
							treat_answer(data);
							console.log(data);
						});
					});
				})()
			}
		});



		//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		///////////////////////////////////////////////////////////////// CLICK ON THE UTILITY BUTTON ////////////////////////////////////////////////////////////////
		/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
		$('.calc_util').click(function() {
			// we store the name of the attribute
			var name = $(this).attr('id').slice(2);
			// we hide the slect div
			$('#select').hide();

			// which index is it ?
			var indice;
			for (var j = 0; j < assess_session.attributes.length; j++) {
				if (assess_session.attributes[j].name == name) {
					indice = j;
				}
			}

			var val_min = assess_session.attributes[indice].val_min;
			var val_max = assess_session.attributes[indice].val_max;
			var mode = assess_session.attributes[indice].mode;
			var points = assess_session.attributes[indice].questionnaire.points.slice();

			if (mode == "normal") {
				points.push([val_max, 1]);
				points.push([val_min, 0]);
			} else {
				points.push([val_max, 0]);
				points.push([val_min, 1]);
			}
			var json_2_send = {
				"type": "calc_util_multi"
			};
			json_2_send["points"] = points;




			function reduce_signe(nombre, dpl=true, signe=true) {

				if (nombre >= 0 && signe==true) {
					if (dpl==false) {
						if (nombre > 999) {
							return ("+" + nombre.toExponential(settings.decimals_equations)).replace("e+", "\\times10^{")+"}";
						}
						else if (nombre < 0.01) {
							return ("+" + nombre.toExponential(settings.decimals_equations)).replace("e-", "\\times10^{-")+"}";
						}
						else {
							return "+" + nombre.toPrecision(settings.decimals_equations);
						}
					}
					else {
						return "+" + nombre.toPrecision(settings.decimals_dpl);
					}
				} else {
					if (dpl==false) {
						if (Math.abs(nombre) > 999) {
							return String(nombre.toExponential(settings.decimals_equations)).replace("e+","\\times10^{")+"}";
						}
						else if (Math.abs(nombre) < 0.01) {
							return String(nombre.toExponential(settings.decimals_equations)).replace("e-", "\\times10^{-")+"}";
						}
						else {
							return nombre.toPrecision(settings.decimals_equations);
						}
					}
					else {
						return nombre.toPrecision(settings.decimals_dpl);
					}
				}
			};

			function addTextForm(div_function, copie, render, key, excel) {

				if (settings.language=="french") {
					excel=excel.replace(/\./gi,",");
				}

				var copy_button_dpl = $('<button class="btn functions_text_form" id="btn_dpl_' + key + '" data-clipboard-text="' + copie + '" title="Click to copy me.">Copy to clipboard (DPL format)</button>');
				var copy_button_excel = $('<button class="btn functions_text_form" id="btn_excel_' + key + '" data-clipboard-text="' + excel + '" title="Click to copy me.">Copy to clipboard (Excel format)</button>');
				var copy_button_latex = $('<button class="btn functions_text_form" id="btn_latex_' + key + '" data-clipboard-text="' + render + '" title="Click to copy me.">Copy to clipboard (LaTeX format)</button>');

				if (settings.language=="french") {
					render=render.replace(/\./gi,",");
				}

				var ajax_render = {
					"type": "latex_render",
					"formula": render
				};

				$.post('ajax', JSON.stringify(ajax_render), function (data) {
					div_function.append("<img src='data:image/png;base64,"+ data +"' alt='"+key+"' />");
					div_function.append("<br /><br />");
					div_function.append(copy_button_dpl);
					div_function.append("<br /><br />");
					div_function.append(copy_button_excel);
					div_function.append("<br /><br />");
					div_function.append(copy_button_latex);
				});

				$('#functions').append(div_function);

				var client = new Clipboard("#btn_dpl_" + key);
				client.on("success", function(event) {
					copy_button_dpl.text("Done !");
					setTimeout(function() {
						copy_button_dpl.text("Copy to clipboard (DPL format)");
					}, 2000);
				});

				var client = new Clipboard("#btn_excel_" + key);
				client.on("success", function(event) {
					copy_button_excel.text("Done !");
					setTimeout(function() {
						copy_button_excel.text("Copy to clipboard (Excel format)");
					}, 2000);
				});

				var client = new Clipboard("#btn_latex_" + key);
				client.on("success", function(event) {
					copy_button_latex.text("Done !");
					setTimeout(function() {
						copy_button_latex.text("Copy to clipboard LaTeX format)");
					}, 2000);
				});
			}

			function addFunctions(i, data) {
				for (var key in data[i]) {

					if (key == 'exp') {
						var div_function = $('<div id="' + key + '" class="functions_graph" style="overflow-x: auto;"><h3 style="color:#401539">Exponential</h3><br />Coefficient of determination: ' + Math.round(data[i][key]['r2'] * 100) / 100 + '<br /><br/></div>');
						var copie = reduce_signe(data[i][key]['a']) + "*exp(" + reduce_signe(-data[i][key]['b']) + "x)" + reduce_signe(data[i][key]['c']);
						var render = reduce_signe(data[i][key]['a'],false, false) + 'e^{' + reduce_signe(-data[i][key]['b'],false) + 'x}' + reduce_signe(data[i][key]['c'],false);
						var excel = reduce_signe(data[i][key]['a']) + "*EXP(" + reduce_signe(-data[i][key]['b']) + "*x)" + reduce_signe(data[i][key]['c']);
						addTextForm(div_function, copie, render, key, excel);
					} else if (key == 'log') {
						var div_function = $('<div id="' + key + '" class="functions_graph" style="overflow-x: auto;"><h3 style="color:#D9585A">Logarithmic</h3><br />Coefficient of determination: ' + Math.round(data[i][key]['r2'] * 100) / 100 + '<br /><br/></div>');
						var copie = reduce_signe(data[i][key]['a']) + "*log(" + reduce_signe(data[i][key]['b']) + "x" + reduce_signe(data[i][key]['c']) + ")" + reduce_signe(data[i][key]['d']);
						var render = reduce_signe(data[i][key]['a'], false, false) + "\\log(" + reduce_signe(data[i][key]['b'], false, false) + "x" + reduce_signe(data[i][key]['c'],false) + ")" + reduce_signe(data[i][key]['d'],false);
						var excel = reduce_signe(data[i][key]['a']) + "*LN(" + reduce_signe(data[i][key]['b']) + "x" + reduce_signe(data[i][key]['c']) + ")" + reduce_signe(data[i][key]['d']);
						addTextForm(div_function, copie, render, key, excel);
					} else if (key == 'pow') {
						var div_function = $('<div id="' + key + '" class="functions_graph" style="overflow-x: auto;"><h3 style="color:#6DA63C">Power</h3><br />Coefficient of determination: ' + Math.round(data[i][key]['r2'] * 100) / 100 + '<br /><br/></div>');
						var copie = reduce_signe(data[i][key]['a']) + "*(pow(x," + (1 - data[i][key]['b']) + ")-1)/(" + reduce_signe(1 - data[i][key]['b']) + ")" + reduce_signe(data[i][key]['c']);
						var render = reduce_signe(data[i][key]['a'], false, false) + "\\frac{x^{" + reduce_signe(1 - data[i][key]['b'], false) + "}-1}{" + reduce_signe(1 - data[i][key]['b'], false) + "}" + reduce_signe(data[i][key]['c'], false);
						var excel = reduce_signe(data[i][key]['a']) + "*(x^" + (1 - data[i][key]['b']) + "-1)/(" + reduce_signe(1 - data[i][key]['b']) + ")" + reduce_signe(data[i][key]['c']);
						addTextForm(div_function, copie, render, key, excel);
					} else if (key == 'quad') {
						var div_function = $('<div id="' + key + '" class="functions_graph" style="overflow-x: auto;"><h3 style="color:#458C8C">Quadratic</h3><br />Coefficient of determination: ' + Math.round(data[i][key]['r2'] * 100) / 100 + '<br /><br/></div>');
						var copie = reduce_signe(data[i][key]['c']) + "*x" + reduce_signe(-data[i][key]['b']) + "*pow(x,2)" + reduce_signe(data[i][key]['a']);
						var render = reduce_signe(data[i][key]['c'], false, false) + "x" + reduce_signe(-data[i][key]['b'], false) + "x^{2}" + reduce_signe(data[i][key]['a'], false);
						var excel = reduce_signe(data[i][key]['c']) + "*x" + reduce_signe(-data[i][key]['b']) + "*x^2" + reduce_signe(data[i][key]['a']);
						addTextForm(div_function, copie, render, key, excel);
					} else if (key == 'lin') {
						var div_function = $('<div id="' + key + '" class="functions_graph" style="overflow-x: auto;"><h3 style="color:#D9B504">Linear</h3><br />Coefficient of determination: ' + Math.round(data[i][key]['r2'] * 100) / 100 + '<br /><br/></div>');
						var copie = reduce_signe(data[i][key]['a']) + "*x" + reduce_signe(data[i][key]['b']);
						var render = reduce_signe(data[i][key]['a'], false, false) + "x" + reduce_signe(data[i][key]['b'], false);
						var excel = reduce_signe(data[i][key]['a']) + "*x" + reduce_signe(data[i][key]['b']);
						addTextForm(div_function, copie, render, key, excel);
					} else if (key=='expo-power') {
						var div_function = $('<div id="' + key + '" class="functions_graph" style="overflow-x: auto;"><h3 style="color:#26C4EC">Expo-Power</h3><br />Coefficient of determination: ' + Math.round(data[i][key]['r2'] * 100) / 100 + '<br /><br/></div>');
						var copie = reduce_signe(data[i][key]['a']) + "+exp(-(" + reduce_signe(data[i][key]['b']) + ")*pow(x," + reduce_signe(data[i][key]['c']) + "))" ;
						var render = reduce_signe(data[i][key]['a'], false, false) + "+exp(" + reduce_signe(-data[i][key]['b'], false, false) + "*x^{" + reduce_signe(data[i][key]['c'], false, false) + "})" ;
						var excel = reduce_signe(data[i][key]['a']) + "+EXP(-(" + reduce_signe(data[i][key]['b']) + ")*x^" + reduce_signe(data[i][key]['c']) + ")" ;
						addTextForm(div_function, copie, render, key, excel);
					}
				}
			}

			function addGraph(i, data, min, max) {
				$.post('ajax', JSON.stringify({
					"type": "svg",
					"data": data[i],
					"min": min,
					"max": max,
					"liste_cord": data[i]['coord'],
					"width": 6
				}), function(data2) {
					$('#main_graph').append(data2);
				});
			}

			function availableRegressions(data) {
				var text = '';
				for (var key in data) {
					if (typeof(data[key]['r2']) !== 'undefined') {
						text = text + key + ': ' + Math.round(data[key]['r2'] * 100) / 100 + ', ';
					}
				}
				return text;
			}


			$.post('ajax', JSON.stringify(json_2_send), function(data) {
				$('#charts').show();
				$('#charts').append('<table id="curves_choice" class="table"><thead><tr><th></th><th>Points used</th><th>Available regressions: r2</th></tr></thead></table>');
				for (var i = 0; i < data['data'].length; i++) {
					regressions_text = availableRegressions(data['data'][i]);
					$('#curves_choice').append('<tr><td><input type="radio" class="radio_choice" name="select" value=' + i + '></td><td>' + data['data'][i]['points'] + '</td><td>' + regressions_text + '</td></tr>');
				}
				$('.radio_choice').on('click', function() {
					$('#main_graph').show().empty();
					$('#functions').show().empty();
					addGraph(Number(this.value), data['data'], val_min, val_max);
					addFunctions(Number(this.value), data['data']);
				});
			});

		});
	});
</script>
<!-- Library to copy into clipboard -->
<script src="{{ get_url('static', path='js/clipboard.min.js') }}"></script>
</body>

</html>
