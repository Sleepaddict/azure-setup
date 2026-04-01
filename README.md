## References
- https://github.com/MicrosoftLearning/mslearn-azure-ml
- https://learn.microsoft.com/en-us/azure/virtual-machines/sizes
- https://learn.microsoft.com/en-us/azure/reliability/regions-list
- https://docs.azure.cn/en-us/machine-learning/how-to-read-write-data-v2


## Setting up Workspace & Compute Resources :heavy_check_mark:
1) Go to https://portal.azure.com and login using your microsoft account
2) Select [>_] cloud shell at the top of the page, select Bash, check correct subscription & no storage account required.
3) Get the setup script from the git repo
    ```bash 
    # Clone setup repo
    git clone https://github.com/Sleepaddict/azure-setup.git
    cd azure-setup/
    
    # change permissions
    chmod +x setup.sh
    ```
4) Run the `setup.sh` script with the following arguments:

    args | help
    | --- | --- |
    | --suffix | Suffix to add to workspace/resource group/compute instance names (default: user1234) |
    | --resource_grp | Name to use for resource group (default: proj-dev) |
    | --region | Region to host resources (default: koreacentral) or 'westus' |
    | --workspace | Name to use for Machine Learning workspace (default: mlw-proj-dev) |
    | --inst_name | Name to use for compute instance (default: ci) |
    | --inst_size | Size of compute instance to use (e.g. Standard_NC40ads_H100_v5) |
    | --clust_name | Name to use for compute cluster (default: aml-cluster) |
    | --clust_size | Size of compute cluster to use (e.g. Standard_NC80adis_H100_v5) |
    | --clust_max_node | Max instance for compute cluster (default: 2) |

## Accessing datastorage container to store custom dataset :heavy_check_mark:
1) From Azure portal > Storage accounts > click on your account (e.g. mlw???storage???)
2) From your storage account > Data storage > Containers > azureml-blobstore-???
3) Upload .zip file of dataset to the container. You may want skip this step and organize this container first by creating `/datasets`, `/codes`, & `/artifacts` subfolders using `mkdir`. (see next section)
4) Unzip using cmd line/code in the compute instance (see next section)

## Accessing Created Compute Instance for Training Jobs :heavy_check_mark:
1) From Azure portal, search for Azure Machine Learning
2) Click on the created workspace > launch studio from Overview
3) Go to compute > compute instances > select Terminal Application from the applications
4) Install the required libraries in the terminal. You may ignore the error messages (if any).
    ```bash
    pip install azure-ai-ml
    pip install azure-identity
    ```
5) Mount your datastorage container to the compute instance. You can find the account-key at your storage account > Security + networking > Access keys
    ```bash
    # Add Microsoft repo
    wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
    sudo dpkg -i packages-microsoft-prod.deb

    # Install blobfuse2
    sudo apt-get update
    sudo apt-get install blobfuse2

    # Create required directories; BlobFuse requires a mount dir and a local cache dir
    mkdir ./blob_mount
    mkdir ./blob_cache

    # Create a config file; 
    # refer to sample_blob_config.yaml or git clone for convenience
    git clone https://github.com/Sleepaddict/azure-setup.git # then edit the sample_blob_config.yaml

    # Mount the container; Now your blob container appears as a filesystem e.g. ~/blob_mount/
    blobfuse2 mount ./blob_mount --config-file=./azure-setup/sample_blob_config.yaml

    # You can interact with it like normal files; Note that the file may not be visible in the GUI, use ls to check
    ls ./blob_mount
    ```
6) You can interact with your files via this compute instance terminal (e.g. unzip datasets, git clone repos) after the container has been mounted.
7) BUT do not call your python scripts directly via the terminal. Submit them as a job instead (see `sample_submit_job.py` in next section) to fully utilize the created compute cluster (i.e. NOT compute instance).
8) If you shutdown the compute instance, you will need to remove the existing `~/blob_cache` and run the <blobfuse2 mount etc etc> cmd again when you boot it up.<br>  
***Note***: you may encounter an error when submitting a job saying it could not get the managed credentials. To solve this, open up any python script/notebook, and you will be prompted to authenticate. Click on authenticate and you will be able to execute Azure ML SDK commands.

## Submitting Training Jobs using Custom Environment
There are 2 ways to do this.
### Using a custom Docker Image
1) Build your image locally
2) Push it to Azure Container Registry (ACR); From Azure portal > search for Container Registry

***Note***: that this method will incur charges for hosting and storing your docker images on Azure

### Using a custom environment YAML (without Docker) :heavy_check_mark:
1) Define an environment using a conda YAML (see `sample_env.yml`)
2) Pass it as an argument when submitting your training job. This lets AML manage the base image on the compute resource instead of having to handle the CUDA drivers etc. yourself

### Submit Job to compute cluster :heavy_check_mark:
1) Call `sample_submit_job.py` with the following arguments.
    args| help
    | --- | --- |
    | --code | specifies the folder that includes the script to run e.g. "./blob_mount/codes/your_repo" |
    | --cmd | what you will usually call via cmd line e.g. "python train-model.py --your_args" ***see Note 3***|
    | --indatapath | input data path e.g. your datastorage container subfolder e.g. azureml://datastores/<data_store_name>/paths/<path>/<training_dataset> ***see Note 2***|
    | --outdatapath | output data path e.g. your datastorage container subfolder e.g. azureml://datastores/<data_store_name>/paths/<path>/<training_artifacts> ***see Note 2***|
    | --weightsdatapath | weight folder path e.g. your datastorage container subfolder e.g. azureml://datastores/<data_store_name>/paths/<path>/<weights> ***see Note 2***|
    | --out_data_mode | choices = [ 'we_decide', 'upload', 'rw_mount' ]<br>Choose 'upload' for faster io but outputs are only saved at the end.<br>Choose 'rw_mount' for immediate output.<br>Choose 'we_decide' to let the script auto select. |
    | --store_local | whether to pre-download the dataset locally & store output artifacts locally first for faster I/O during training ***see Note 1***|
    | --env | specifies the necessary packages/environment to use for running the command, or can be a yml file e.g. "my-custom-env:1" or "sample_env.yml" |
    | --env_name | name to use for your custom environment if any |
    | --compute | name of compute cluster to use for the job e.g. "aml-cluster"|
    | --display_name | display name to use for the job e.g. "diabetes-train-run1" |
    | --expt_name | name of expt that the job belongs to e.g. "diabetes-training"|

***Note 1***: Use `store_local` only if your dataset can fit entirely on the job VM (i.e. compute cluster)

***Note 2***: To find the path of your datastorage container go to Azure Machine Learning studio > Data > Datastores > workspaceblobstore > Browse > select the `...` for the folder that you want > copy URI. For your `--outdatapath`, ensure that it is an empty/new subfolder if not your artifacts will not be uploaded at the end of the job.

***Note 3a***: Azure will auto-resolve your datastorage paths on-the-fly into a local folder like `/mnt/azureml/cr/j/xyz/inputs/input_data/` on the compute VM when the job is composed. This will most likely break your training if your dataset files contain absolute paths which cannot be found.

***Note 3b***: A 'cleaner' workaround is to ask AML to subst all input data paths to `${{inputs.input_data}}` and all artifact output paths to `${{outputs.output_data}}`. This can be done in the string passed to `--cmd` arg when calling `sample_submit_job.py`.

***Note 3c***: E.g. when trying to train Yolov7 on MS COCO...
#### Original Yolov7 train **`--cmd`** will not work due to path resolve issues (see Note 3a)
```bash
--cmd "python train.py --workers 8 --device 0 --batch-size 32 \
       --data data/coco.yaml --img 640 640 --cfg cfg/training/yolov7.yaml \
       --weights 'yolov7_training.pt' --name yolov7 --hyp data/hyp.scratch.p5.yaml"
```

#### Update data paths dynamically when passing **`--cmd`** and also brute-force replace all image paths defined in the .txt files for MSCOCO
- Note: this sample code uses train8.txt and val8.txt because am using a mini subset of MSCOCO (coco8) for debugging purposes only.
```bash
--cmd "export DATA_ROOT=\${{inputs.input_data}} && \
    sed -i \"s|^train:.*|train: \$DATA_ROOT/train8.txt|\" data/coco.yaml && \
    sed -i \"s|^val:.*|val: \$DATA_ROOT/val8.txt|\" data/coco.yaml && \
    sed -i \"s|^\./||\" \$DATA_ROOT/train8.txt && sed -i \"s|^|\$DATA_ROOT/|\" \$DATA_ROOT/train8.txt && \
    sed -i \"s|^\./||\" \$DATA_ROOT/val8.txt && sed -i \"s|^|\$DATA_ROOT/|\" \$DATA_ROOT/val8.txt && \
    python train.py --workers 8 --device 0 --batch-size 32 --data data/coco.yaml --img 640 640 --cfg cfg/training/yolov7.yaml --weights 'yolov7_training.pt' --name yolov7 --hyp data/hyp.scratch.p5.yaml --project \${{outputs.output_data}}"
```
- `path: ${{inputs.input_data}}`: This resolves to something like `/mnt/azureml/.../datasets/coco`
- Inside your `train2017.txt`, brute force image paths to absolute paths `${{inputs.input_data}}/images/train2017/img1.jpg`.
- Include `${{outputs.output_data}}` to ensure your training artifacts are properly output onto your datastorage container at the end of the job; else job will succeed but you will lose all output files.

#### Example full call for submitting job becomes
```bash 
python ./azure-setup/sample_submit_job.py \
--code ./blob_mount/codes/yolov7/ \
--cmd "export DATA_ROOT=\${{inputs.input_data}} && \
sed -i \"s|^train:.*|train: \$DATA_ROOT/train8.txt|\" data/coco.yaml && \
sed -i \"s|^val:.*|val: \$DATA_ROOT/val8.txt|\" data/coco.yaml && \
sed -i \"s|^\./||\" \$DATA_ROOT/train8.txt && sed -i \"s|^|\$DATA_ROOT/|\" \$DATA_ROOT/train8.txt && \
sed -i \"s|^\./||\" \$DATA_ROOT/val8.txt && sed -i \"s|^|\$DATA_ROOT/|\" \$DATA_ROOT/val8.txt && \
python train.py --workers 8 --device 0 --batch-size 32 --data data/coco.yaml --img 640 640 --cfg cfg/training/yolov7.yaml --weights 'yolov7_training.pt' --name yolov7 --hyp data/hyp.scratch.p5.yaml --project \${{outputs.output_data}}" \
--indatapath "azureml://datastores/<data_store_name>/paths/<path>" \
--outdatapath "azureml://datastores/<data_store_name>/paths/<path>" \
--store_local --env ./azure-setup/sample_env.yaml --env_name yolov7 \
--compute aml-clusteruser1234 --display_name yolov7_coco8_single_gpu --expt_name setup_azure
```

***Note 4***: files ignored by .gitignore will not be submitted to the job, which can cause FileNotFoundError
