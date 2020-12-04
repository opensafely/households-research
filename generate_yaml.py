action_template = """
  run_model_{ridus}_{seed}:
    run: python:latest python analysis/opensafely_age_hh_th.py --starting-parameter {seed} --add-ridge {rid}
    needs: [generate_model_data]
    outputs:
      moderately_sensitive:
        log: opensafely_age_hh_ridge_{ridus}_and_seed_{seed}.log
"""
 
seeds = [ 1, 3, 5, 81, 83, 85, 23, 37 ]
ridges = [ 20.1 , 54.6 ]
 
for s in seeds:
    for r in ridges:
        print(action_template.format(seed = s, rid = r, ridus = str(r).replace('.','_')))
 
for s in seeds:
    for r in ridges:
        print("run_model_{ridus}_{seed},".format(seed = s, rid = r, ridus = str(r).replace('.','_')))