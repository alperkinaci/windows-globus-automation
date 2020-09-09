# DATA TRANSFER FROM WINDOWS SERVER USING GLOBUS
<hr>

This document outlines an example setup to automate data transfers from
Windows server to a Linux machine via Globus. 

### KLC (QUEST) TO DO
Quest storage has a managed Globus endpoint, however managed endpoints
can be activated for a maximum of seven days before manual re-activation
in the Globus web UI is required. In automating the transfers, the manual
process poses an issue. To overcome this difficulty, you can create
"shared endpoints" within a managed endpoint that do not need re-activation
and use them like any other endpoint. This new endpoint should include the
"incoming" directory so the data can be sent to this folder directly from
your local server.

The setup instructions to create a shared endpoint is [here](https://kb.northwestern.edu/page.php?id=71271)

When setting up this shared endpoint, create a distinct and recognizable
"Display Name" so that you can identify it when you search endpoints. For
example "YourLabName-Quest".

Note that the directory of the shared endpoint will be used as the "incoming"
folder for the data that will be sent from the Windows server.

### LOCAL SERVER TO DO

#### I- Install Globus Connect Personal
Globus service can transfer data to/from a local server if the server has a Globus
endpoint. To create an endpoint on your device you should install "Globus
Connect Personal" application. The installation and configuration instructions
can be found in [this link](https://kb.northwestern.edu/page.php?id=71271)
and the links therein:

You will assign a path that Globus can access on your Windows server. You can
set your "outgoing" folder as the path for your personal endpoint so that only
this folder will be accessible by Globus.

#### II- Setting Up Python
The Globus transfers can be automated using Globus command line interface (CLI).
There are couple of ways to install CLI depending on whether you have python
in your local Windows system or not.

***New Python***

If you don't have python in the PATH of the server, you can
install [Miniconda3](https://docs.conda.io/en/latest/miniconda.html). After
installation, the Path environment variable should be modified.

Search for "environment variables" in the start menu search. Click on
the "Edit the system environment variables".

![search](/imagese/nv-var1.png)

On the newly opened "System Properties" box, click "Environment Variables"

![systemprop](/images/env-var2a.png)

Select "Path" variable and click "Edit"

![envvar](/images/env-var3a.png)

Click "New"

![path](/images/env-var4a.png)

Add the following lines

```code
C:\path\to\Miniconda3
C:\path\to\Miniconda3\Scripts
C:\path\to\Miniconda3\Library\bin
```

Once the lines are added click on OKs and close the configuration boxes.
If the Path environment variable has been set correctly, you should be able
to run Python or Conda commands in Windows Command Prompt. To verify conda,
issue the following command on Command Prompt:

```cmd
conda --help
```

For an easier package management, the globus-cli will be installed in a
conda environment. To create an environment called globus with python and
pip installed, issue the following command:

```cmd
conda create --no-default-packages -n globus python pip
```

Once the installation completes, the environment can be activated by

```cmd
activate globus
```

***Existing Python***

If you already have python(3.6+) and pip in Path of the server,
you can create a virtual environment using venv package. If the Path has
been set up correctly, you should be able to run python command in Windows
Command Prompt.

```conda
python --version
```

To create the globus virtual environment:

```code
python -m venv C:\path\to\globus
```

The environment can be activated via

```code
C:\path\to\globus\Scripts\activate.bat
```

#### III- Globus CLI Installation

Once your environment (through conda or venv) is activated, you can install globus-cli
package withing the environment.

```cmd
pip install globus-cli
```

After the installation, see that CLI is installed:
```cmd
globus --help
```

#### IV- Setting Up Transfer

To setup the transfer, first you need to obtain the endpoint IDs for your
Shared Endpoint on Quest and Personal Connect endpoint on your local computer.

On the Windows Command Prompt search for the names of your endpoints and
note the IDs:

```cmd
globus endpoint search 'NameOfYourQuestEndpoint'
globus endpoint search 'NameOfYourPersonalEndpoint'
```

Assuming a conda environment is created and globus-cli is installed within
that environment, we will use a Powershell script to automate the transfers.

Let's name our Powershell script as *globus-transfer.ps1* and include the
following in the script

```powershell
#Set source endpoint (i.e. personal endpoing on the local server)
$source_ep='Full-ID-string-of-personal-endpoint'

#Set destination endpoint (i.e. Quest shared endpoint)
$dest_ep='Full-ID-string-of-shared'

#Start the transfer with Globus and record the task ID for this transfer.
#Both endpoint folders are the exact access paths for the endpoint.
#All the files/folders under the source path are recursively transfered to destination.
$task_id= globus transfer --checksum-algorithm MD5 --verify-checksum ${source_ep}:\ ${dest_ep}:/ --jmespath 'task_id' --format=UNIX --recursive

#If your "outgoing" foder is a subfolder of your personal endpoint path then
#use the following instead:
# $task_id= globus transfer --checksum-algorithm MD5 --verify-checksum ${source_ep}:\outgoing ${dest_ep}:/ --jmespath 'task_id' --format=UNIX --recursive

#Check the status of the transfer after 5 minutes
$transfer_status= globus task wait --timeout 300 --format json "$task_id"

#Continue to check the status until the transfer status reports success
while("$transfer_status" -notmatch "\bSUCCEEDED\b") {
    $transfer_status= globus task wait --timeout 300 --format json "$task_id";
    }

#Deactivate conda environment
conda deactivate
```

Now it is time to schedule to run the script via Windows "Task Scheduler."

![search](/images/task-sched1.png)

On the Task Scheduler Action tab, clock on "Create Task"

![search](/images/task-sched2.png)

Give a name to your new task and select to run the task whether the user is
logged on or not. You may also add a description. No other changes are
needed here.

![search](/images/task-sched3.png)

Click on the "Actions" tab and then select new. We will create three
actions.

![search](/images/task-sched4.png)

The three actions (in order of processing) will have the following configurations:

**i)** This action sets Conda for Powershell.

**Action:** Start a program

**Program/script:** powershell.exe

**Add arguments:** -Command "conda init"

**ii)** This action activates conda environment, sets execution policy for
powershell script and runs it.

**Action:** Start a program

**Program/script:** powershell.exe

**Add arguments:** -Command "Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy ByPass -Force; conda activate globus; C:\path\to\globus-transfer.ps1"

**iii)** This action unsets Conda for Powershell

**Action:** Start a program

**Program/script:** powershell.exe

**Add arguments:** -Command "conda init --reverse"

To complete the automation process, you could also click on the "Triggers" tab
on the "Create Task" box. The trigger could be a time of day to schedule daily
transfers.

![search](/images/task-sched5.png)
