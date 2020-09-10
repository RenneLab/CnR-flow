
Example Files
=============

.. contents::
   :local:


Task nextflow.config
--------------------

This nextflow.config file is copied to the task directory by the command:

.. code-block:: bash
  
    #mkdir ./my_task_dir
    #cd ./my_task_dir
    nextflow run RenneLab/CnR-flow --mode initiate

This configuration file contains paramaters for input file and task 
workflow setup.

.. literalinclude:: ../../templates/nextflow.config.task.backup
   :caption: .../my_task_dir/nextflow.config (Task Settings)
   :name: task_config_file


Pipe nextflow.config
--------------------

This nextflow.config file is contains configuration
paramaters for pipeline setup.

.. literalinclude:: ../../templates/nextflow.config.backup
   :caption: .../CnR-flow/nextflow.config (Pipe Settings)
   :name: pipe_config_file


Task nextflow.config (no comments)
----------------------------------

This nextflow.config file is equivalent to :ref:`Task nextflow.config`,
but with comments removed.

.. literalinclude:: ../../templates/nextflow.config.task.nodoc.backup
   :caption: .../my_task_dir/nextflow.config.nodoc (Task Settings, Without Comments)
   :name: task_config_file_nodoc


Task nextflow.config (minimal)
----------------------------------

This nextflow.config file is equivalent to the task and executor
settings only from :ref:`Task nextflow.config`, with comments removed.

.. literalinclude:: ../../templates/nextflow.config.task.nodoc.minimal.backup
   :caption: .../my_task_dir/nextflow.config.minimal (Task Settings, Minimal Without Comments)
   :name: task_config_file_minimal
