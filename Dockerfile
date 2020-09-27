FROM debian

# Install ClamAV
RUN apt-get update
RUN apt-get install -y clamav clamav-daemon

# Update Virus Database during docker Build (example only)
RUN freshclam

# Scan Target folder recursively
CMD clamscan -r /target
