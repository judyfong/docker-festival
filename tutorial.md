# Installing Docker
* Install docker : https://www.docker.com/
* Recommended for Linux users (needed for Visual Studio Code integration):
    * Add yourself to the docker system group:
        * `sudo usermod -aG docker $USER`
        * restart your system


# Installing VS code and extensions (recommended)
This is recommended for those with little prior experience with Docker.
* [Install VS Code](https://code.visualstudio.com/)
* Open VS Code (VSC)
* Install the `docker` VSC extension by opening the extensions pane on the left (ctrl+shift+X) and search for `ms-azuretools.vscode-docker` and hit install
* Install the `remote development` VSC extension, search for `ms-vscode-remote.vscode-remote-extensionpack`. Follow the [guide here](https://code.visualstudio.com/docs/remote/containers) to complete installation


# Getting the image
* Build from `dockerfile` by entering this directory and run `docker build --tag festival`
* pull the 2016 SLTU tutorial image with `docker pull mjansche/tts-tutorial-sltu2016`


# About the image
When you have pulled the image, run `docker run --rm -it mjansche/tts-tutorial-sltu2016`
* You now have a shell running in the container.
* The main contents of the image are located at `/usr/local/src`.
...


# Using the image in VSC
After pulling the image, it should now appear under the `images` row in the `Docker` pane on the left inside VSC (click the icon of the whale carrying containers)
* Click the image
* Right click the `latest` pop-under
* Select `run`
* A container for the image will now appear under the `containers` row in the `Docker` pane with a green play icon. Right click it and select `Attach Visual Studio Code`.
* A new VSC window will open. This will be the code editor for your work.
* You can use the shell of the newly created container by clicking `Terminal` -> `New Terminal` (or Ctrl+ Shift + `)
* The contents of the image will now appear under the VSC explorer (Ctrl + Shift + E)
* Next time you open up VSC you:
    * Open the `Docker` pane
    * Find your container
    * Right click and press `start`
    * Refresh the containers row (hower over `containers` and a refresh icon appears)
    * And attach to VSC as explained above
* Go next to "Using the image"

# Using the image without VSC
As with any image run the image in a container via `docker run --rm -it <image_name>`


# Using the image
Make sure you have followed the steps above and start the container for your image.
* You might want to use some familiar tools. Do:
    * `apt-get update`
    * Install a package, e.g. `apt-get install nano`
* Create a directory for your voice:
    * `mkdir voice_building`
    * `cd voice_building`
    * Run `../goog_af_unison_text/build-voice.sh`