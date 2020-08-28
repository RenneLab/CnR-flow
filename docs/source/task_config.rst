
Task Config
===========

This nextflow.config file is copied to the task directory by the command:

.. code-block:: bash
  
    #mkdir ./my_task_dir
    #cd ./my_task_dir
    nextflow run dstrib/CnR-flow --mode initiate

This configuration file contains paramaters for input file and task 
workflow setup.

.. literalinclude:: ../../templates/nextflow.config.task_default.backup
   :caption: .../my_task_dir/nextflow.config (Task Settings)
   :name: task_config_file
