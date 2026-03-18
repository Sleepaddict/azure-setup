import argparse

from azure.identity import DefaultAzureCredential, InteractiveBrowserCredential
from azure.ai.ml import MLClient, command, Input, Output
from azure.ai.ml.entities import Environment
from azure.ai.ml.constants import AssetTypes, InputOutputModes

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Sample script to submit compute job'
    )
    parser.add_argument('--code', type=str,
                        help='path to folder that includes the script to run e.g. "./src"')
    parser.add_argument('--cmd', type=str,
                        help='what you will usually call via cmd line e.g. "python train-model-parameters.py --training_data diabetes.csv"')
    parser.add_argument('--indatapath', type=str,
                        help='input data path e.g. your datastorage container subfolder e.g. azureml://datastores/<data_store_name>/paths/<path>/<training_dataset>')
    parser.add_argument('--outdatapath', type=str,
                        help='output data path e.g. your datastorage container subfolder e.g. azureml://datastores/<data_store_name>/paths/<path>/<training_artifacts>')
    parser.add_argument('--store_local', action='store_true',
                        help='whether to pre-download the dataset locally & store output artifacts locally first for faster I/O during training')
    parser.add_argument('--env', type=str,
                        help='specifies the necessary packages/environment to use for running the command, or can be a yml file e.g. "my-custom-env:1" or "sample_env.yml"')
    parser.add_argument('--env_name', type=str,
                        help='name to use for your custom environment if any')
    parser.add_argument('--compute', type=str,
                        help='name of compute cluster to use for the job e.g. "aml-cluster"')
    parser.add_argument('--display_name', type=str,
                        help='display name to use for the job e.g. "diabetes-train-script"')
    parser.add_argument('--expt_name', type=str,
                        help='name of expt that the job belongs to e.g. "diabetes-training"')
    args = parser.parse_args()

    # +---------------------------+
    # | Connect to your workspace |
    # +---------------------------+
    # To connect to a workspace, we need identifier parameters 
    # - a subscription ID, resource group name, and workspace name. 
    # Since you're working with a compute instance managed by 
    # Azure Machine Learning, you can use the default values to connect to the workspace.
    try:
        credential = DefaultAzureCredential()
        # Check if given credential can get token successfully.
        credential.get_token("https://management.azure.com/.default")
    except Exception as ex:
        # Fall back to InteractiveBrowserCredential in case DefaultAzureCredential not work
        credential = InteractiveBrowserCredential()
    # Get a handle to workspace
    ml_client = MLClient.from_config(credential=credential)

    # +-----------------------------+
    # | Register custom environment |
    # +-----------------------------+
    ENV_NAME = args.env_name if args.env_name else "my-custom-env"
    if '.yaml' in args.env:
        # build from custom yaml
        my_env = Environment(
            name=ENV_NAME,
            description="My custom conda environment",
            conda_file=args.env,
            image="mcr.microsoft.com/azureml/openmpi4.1.0-ubuntu20.04:latest"  # Let AML manage base image
        )
    else:   
        # register docker image
        my_env = Environment(
            name=ENV_NAME,
            description="My custom docker environment",
            image=args.env, # "myregistry.azurecr.io/my-aml-image:latest",
            conda_file=None,  # Not needed if your Docker already has everything
        )
    try:
        ml_client.environments.create_or_update(my_env)
    except:
        print(f"Could not register or create environment: {args.env}")
    
    # +--------------------------+
    # | Register data I/O for job |
    # +--------------------------+
    IN_DATA_MODE = "download" if args.store_local else "ro_mount"
    OUT_DATA_MODE = "upload" if args.store_local else "rw_mount"
    inputs = {
        "input_data": Input(
            type=AssetTypes.URI_FOLDER,
            path=args.indatapath,
            mode=IN_DATA_MODE
        )
    }

    outputs = {
        "output_data": Output(
            type=AssetTypes.URI_FOLDER,
            path=args.outdatapath,
            mode=OUT_DATA_MODE
        )
    }
    
    # +--------------------+
    # | Submit command job |
    # +--------------------+
    # configure job
    job = command(
        code=args.code,
        command=args.cmd,
        inputs=inputs,
        outputs=outputs,
        environment=ENV_NAME+"@latest",
        compute=args.compute,
        display_name=args.display_name,
        experiment_name=args.expt_name
        )

    # submit job
    returned_job = ml_client.create_or_update(job)
    aml_url = returned_job.studio_url
    print("Monitor your job at", aml_url)