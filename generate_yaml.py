
action_template = """
  run_model_{ridus}_{seed}:
    run: python:latest python analysis/opensafely_age_hh_th.py --starting-parameter {seed} --add-ridge {rid}
    needs: [generate_model_data]
    outputs:
      moderately_sensitive:
        log: opensafely_age_hh_ridge_{ridus}_and_seed_{seed}.log
"""

seeds = [ 13, 15, 19, 42, 56, 80 ]
ridges = [ 0.0, 7.4, 20.0 ]

for s in seeds:
    for r in ridges:
        print(action_template.format(seed = s, rid = r, ridus = str(r).replace('.','_')))

for s in seeds:
    for r in ridges:
        print("run_model_{ridus}_{seed},".format(seed = s, rid = r, ridus = str(r).replace('.','_')))



