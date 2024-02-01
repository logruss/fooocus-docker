# Docker image for Fooocus: Focus on prompting and generating

## Installs

-   Ubuntu 22.04 LTS
-   CUDA 11.8
-   Python 3.10.12
-   [Fooocus](https://github.com/lllyasviel/Fooocus) 2.1.864
-   Torch 2.0.1
-   xformers 0.0.22
-   [runpodctl](https://github.com/runpod/runpodctl)
-   [croc](https://github.com/schollz/croc)
-   [rclone](https://rclone.org/)

## Available on RunPod

This image is designed to work on [RunPod](https://runpod.io?ref=2xxro4sy).
You can use my custom [RunPod template](https://runpod.io/gsc?template=ileyo7dtpj&ref=2xxro4sy)
to launch it on RunPod.

## Running Locally

### Install Nvidia CUDA Driver

-   [Linux](https://docs.nvidia.com/cuda/cuda-installation-guide-linux/index.html)
-   [Windows](https://docs.nvidia.com/cuda/cuda-installation-guide-microsoft-windows/index.html)

### Start the Docker container

```bash
docker run -d \
  --gpus all \
  -v /workspace \
  -p 3000:3001 \
  -p 8888:8888 \
  -e JUPYTER_PASSWORD=Jup1t3R! \
  ashleykza/fooocus:latest
```

You can obviously substitute the image name and tag with your own.

### Ports

| Connect Port | Internal Port | Description |
| ------------ | ------------- | ----------- |
| 3000         | 3001          | Fooocus     |
| 8888         | 8888          | Jupyter Lab |

### Environment Variables

| Variable           | Description                                  | Default   |
| ------------------ | -------------------------------------------- | --------- |
| JUPYTER_PASSWORD   | Password for Jupyter Lab                     | Jup1t3R!  |
| DISABLE_AUTOLAUNCH | Disable Web UIs from launching automatically | (not set) |
| PRESET             | Fooocus Preset (anime/realistic)             | (not set) |

### Rclone Environment Variables

This configuration is used to connect to an SFTP server for downloading models, loras, and for mounting the outputs directory. The script will establish a connection to your SFTP server and download the specified models in the `CHECKPOINTS_TO_DOWNLOAD` variable. Loras are downloaded automatically. A `Data` directory, with subfolders - `checkpoints`, `loras`, and `outputs` directories, will be automatically created in the `WORKING_DIR` directory. The `outputs` directory will be mounted to the container, allowing generated images to be saved directly to the server.

| Variable                  | Description                                                                                                                   | Default      |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------- | ------------ |
| `USE_RCLONE`              | Enables or disables rclone functionality. Set to `disabled` to disable.                                                       | `enabled`    |
| `WORKING_DIR`             | The working directory for rclone operations.                                                                                  | `/workspace` |
| `REMOTE`                  | The rclone remote name. Required if `USE_RCLONE` is enabled.                                                                  | (not set)    |
| `SFTP_HOST`               | The SFTP host address. Required if `USE_RCLONE` is enabled.                                                                   | (not set)    |
| `SFTP_USER`               | The SFTP username. Required if `USE_RCLONE` is enabled.                                                                       | (not set)    |
| `SFTP_PASS`               | The SFTP password. Required if `USE_RCLONE` is enabled.                                                                       | (not set)    |
| `CHECKPOINTS_TO_DOWNLOAD` | Models to be downloaded from the Rclone server, specified by name. Example: `checkpoint1.safetensors checkpoint2.safetensors` | (not set)    |

### Download file from any URL

To download a file, such as a model, from any URL (e.g., from Hugging Face), you can utilize the MODELS_URLS environment variable. In cases where the URL demands an authorization token, the M_API_TOKEN environment variable should be employed.

Note: The downloaded model will be saved in the WORKING_DIR/data/checkpoints directory.

#### Environment Variables

| Variable      | Description                                                                                                                                                                      | Default   |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| `MODELS_URLS` | Specifies the URLs from which to download files. These should be space-separated. For example: https://example.com/model1 https://example.com/model2                             | (not set) |
| `M_API_TOKEN` | The authorization token required by the URL, if any. Note that only a single token can be used, implying that all URLs in MODELS_URLS must be accessible from the same provider. | (not set) |

## Logs

Fooocus creates a log file, and you can tail the log instead of
killing the service to view the logs.

| Application | Log file                    |
| ----------- | --------------------------- |
| Fooocus     | /workspace/logs/fooocus.log |

For example:

```bash
tail -f /workspace/logs/fooocus.log
```

## Community and Contributing

Pull requests and issues on [GitHub](https://github.com/ashleykleynhans/fooocus-docker)
are welcome. Bug fixes and new features are encouraged.

You can contact me and get help with deploying your container
to RunPod on the RunPod Discord Server below,
my username is **ashleyk**.

<a target="_blank" href="https://discord.gg/pJ3P2DbUUq">![Discord Banner 2](https://discordapp.com/api/guilds/912829806415085598/widget.png?style=banner2)</a>

## Appreciate my work?

<a href="https://www.buymeacoffee.com/ashleyk" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" style="height: 60px !important;width: 217px !important;" ></a>
