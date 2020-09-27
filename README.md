# clamavvolumescan
A reference example of how ClamAV can scan attached volume

# ClamAV General Information

A malware scanning using ClamAV is the most affordable and easy in use option.
ClamAV is a very popular Open Source antimalware multi-platform tool.
It has great performance and small memory footprint. 
It can be easily inserted in a container.

[ClamAV Website](https://www.clamav.net/)

## High Performance
ClamAV includes a multi-threaded scanner daemon, command-line utilities for on-demand file scanning and automatic signature updates.

## Versatile
ClamAV supports multiple file formats, file and archive unpacking, and multiple signature languages.

# Reference Example of ClamAV setup in a docker container for testing

The code below installs ClamAV command-line scanner and daemon in a Linux container based on Debian image

## An example of Dockerfile
[The full version is at GitHub](https://github.com/dimkdimk/clamavvolumescan)

```
FROM debian

# Install ClamAV
RUN apt-get update
RUN apt-get install -y clamav clamav-daemon

# Update Virus Database during docker Build (example only)
RUN freshclam

# Scan Target folder recursively
CMD clamscan -r /target

```
## Build image example
```
docker build --no-cache --pull --rm -f "Dockerfile" -t dimkdimk/clamavvolumescan:latest "."
```


## Start docker container with the  MOUNTED VOLUME for scan ( In Windows Docker Desktop) :


```
docker container run --name clam -v C:/DockerData:/target dimkdimk/clamavvolumescan:latest
```
>
> NOTE:
> /target - is where all files for scanning must be placed
> C:/DockerData - is a shared folder on Windows machine ( For Docker Desktop on Windows only )
>


### The full list of "clamscan" command options:
[Scan Documentation](https://www.clamav.net/documents/scanning)

### Examples

```
Scan a file for vulnerabilities:
clamscan path/to/file
Scan all files recursively in a specific directory:
clamscan -r path/to/directory
Scan data from stdin:
command | clamscan -
Specify a virus database file or directory of files:
clamscan --database path/to/database_file_or_directory
Scan the current directory and output only infected files:
clamscan --infected
Output the scan report to a log file:
clamscan --log path/to/log_file
Move infected files to a specific directory:
clamscan --move path/to/quarantine_directory
Remove infected files:
clamscan --remove yes
```
### Return Values of clamscan



```
0 : No virus found.
1 : Virus(es) found.
2 : Some error(s) occurred.
```



# Run C# .NET Core Application in Linux container with pre-configured ClamAV
One of the ClamAV integration methods can be running C# .NET Code in a Linux container where ClamAV is pre-deployed.
This method allows more flexibility to trigger malware scan.

The following .NET Core application patterns can be introduced:
- Batch scanning process on schedule or polling for files in a folder
- A new scan can be triggered by an Event queue ( RabbitMQ, Event Grid, etc )
- Web API .NET Core app that accepts a file as upload and scans it
- Blob Storage enumerator that downloads blobs locally and scans them
- An event-driven application that gets events from Azure Blob Storage Change-feed events.



[Example of code to run bash](https://jackma.com/2019/04/20/execute-a-bash-script-via-c-net-core/)


  
```
public static class ShellHelper
  {
    public static Task<int> Bash(this string cmd, ILogger logger)
    {
      var source = new TaskCompletionSource<int>();
      var escapedArgs = cmd.Replace("\"", "\\\"");
      var process = new Process
                      {
                        StartInfo = new ProcessStartInfo
                                      {
                                        FileName = "bash",
                                        Arguments = $"-c \"{escapedArgs}\"",
                                        RedirectStandardOutput = true,
                                        RedirectStandardError = true,
                                        UseShellExecute = false,
                                        CreateNoWindow = true
                                      },
                        EnableRaisingEvents = true
                      };
      process.Exited += (sender, args) =>
        {
          logger.LogWarning(process.StandardError.ReadToEnd());
          logger.LogInformation(process.StandardOutput.ReadToEnd());
          if (process.ExitCode == 0)
          {
            source.SetResult(0);
          }
          else
          {
            source.SetException(new Exception($"Command `{cmd}` failed with exit code `{process.ExitCode}`"));
          }

          process.Dispose();
        };

      try
      {
        process.Start();
      }
      catch (Exception e)
      {
        logger.LogError(e, "Command {} failed", cmd);
        source.SetException(e);
      }

      return source.Task;
    }
  }
```



