# Bitrise build through Fork

This script allows you to fire [Bitrise](https://app.bitrise.io) builds directly from [Fork](https://git-fork.com/) on MacOS.

## 🔧 Setup
### ⚠️ Prerequisites
- Create an `API_TOKEN` on [Bitrise](https://app.bitrise.io/me/account/security) (better without expiration).
- Find the `APP_SLUG` by navigating to the involved project and keeping the final identifier of the URL (i.e. `https://app.bitrise.io/app/<APP_SLUG>`)
- Find the personal `BUILD_TRIGGER_TOKEN` by simulating the _Start build_ action from Bitrise project page, choosing the _Advanced_ option, scrolling to the bottom to _Generated cURL command_ and grabbing the `build_trigger_token` parameter.

Once you retrieved all these information, we can setup the script by setting respectively `API_TOKEN`, `BUILD_TRIGGER_TOKEN` and `APP_SLUG`.

Save the script in the folder `~/Library/Application Support/com.DanPristupov.Fork` keeping in mind the name of the script (whether you decided to change it).
 
### 🍴 Add the custom command on Fork
Now that everything is in its place, you can open Fork app, navigate to _Settings..._ (`Fork > Settings...` or `⌘ + ,`), click on _Custom Commands_ and create a new _Branch Custom Command_.

Enable `Local Branch` and `Remote Branch` flags, set a name to the command (i.e. _Bitrise build..._), select the `Action` option and insert the following bash command:

```shell
cd ~/Library/Application\ Support/com.DanPristupov.Fork
./bitrise_build_with_branch.sh ${ref}
```
NOTE: Whether you changed the script name, be sure you invoke it with the correct name in the bash command.

Save everything, close the preferences and you're ready to use it.

## 🚀 Usage
The usage is really simple. Just right-click the branch you want to fire a build for, select the custom command at the end of the menu (you should find it with the name you set when creating the command, in my case _Bitrise build..._). This will fire the script that will show a dialog through which you can select a workflow and, then, a prompt for the optional build message.

If everything went smoothly the build should start and Fork will show a success message whit the link to the launched build.

## 🤝🏼 Contributions
Contributions, advices and improvements are always welcome. Feel free to open `Issues` or `Pull Requests` and I will take a look at them as soon as possible.

---

A Special thanks goes to [Fabio Nisci](https://github.com/fabiosoft) who intrigued and stimulated me in the creation of this script.
