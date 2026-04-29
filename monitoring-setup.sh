#!/bin/bash
set -e

# Update system
yum update -y
yum install -y wget curl tar gzip

# Create prometheus user
useradd --no-create-home --shell /bin/false prometheus || true
useradd --no-create-home --shell /bin/false node_exporter || true

# Download and install Prometheus
cd /tmp
PROMETHEUS_VERSION="2.51.0"
wget https://github.com/prometheus/prometheus/releases/download/v$PROMETHEUS_VERSION/prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
tar -xzf prometheus-$PROMETHEUS_VERSION.linux-amd64.tar.gz
cd prometheus-$PROMETHEUS_VERSION.linux-amd64

mkdir -p /etc/prometheus /var/lib/prometheus
cp prometheus /usr/local/bin/
cp promtool /usr/local/bin/
cp -r consoles /etc/prometheus
cp -r console_libraries /etc/prometheus

# Create Prometheus config
cat > /etc/prometheus/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

alerting:
  alertmanagers: []

rule_files: []

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node'
    static_configs:
      - targets: ['${app_instance_1_ip}:9100', '${app_instance_2_ip}:9100']

  - job_name: 'alb'
    metrics_path: '/metrics'
    static_configs:
      - targets: ['localhost:9100']
EOF

chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus
chown prometheus:prometheus /usr/local/bin/prometheus /usr/local/bin/promtool

# Create Prometheus systemd service
cat > /etc/systemd/system/prometheus.service <<'EOF'
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
  --config.file /etc/prometheus/prometheus.yml \
  --storage.tsdb.path /var/lib/prometheus/ \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus

# Download and install Node Exporter on this instance
cd /tmp
NODE_EXPORTER_VERSION="1.7.0"
wget https://github.com/prometheus/node_exporter/releases/download/v$NODE_EXPORTER_VERSION/node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
tar -xzf node_exporter-$NODE_EXPORTER_VERSION.linux-amd64.tar.gz
cd node_exporter-$NODE_EXPORTER_VERSION.linux-amd64
cp node_exporter /usr/local/bin/
chown node_exporter:node_exporter /usr/local/bin/node_exporter

# Create Node Exporter systemd service
cat > /etc/systemd/system/node_exporter.service <<'EOF'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
  --collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($$|/) \
  --collector.filesystem.fs-types-exclude=^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore|rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)($$|/)

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# Download and install Grafana
cd /tmp
GRAFANA_VERSION="10.3.3"
wget https://dl.grafana.com/oss/release/grafana-$GRAFANA_VERSION.linux-amd64.tar.gz
tar -xzf grafana-$GRAFANA_VERSION.linux-amd64.tar.gz
mkdir -p /opt/grafana
mv grafana-$GRAFANA_VERSION /opt/grafana

# Create Grafana systemd service
cat > /etc/systemd/system/grafana-server.service <<'EOF'
[Unit]
Description=Grafana
Wants=network-online.target
After=network-online.target

[Service]
Type=notify
ExecStart=/opt/grafana/grafana-$GRAFANA_VERSION/bin/grafana-server \
  --homepath=/opt/grafana/grafana-$GRAFANA_VERSION
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable grafana-server
systemctl start grafana-server

# Install node_exporter on app instances
for ip in ${app_instance_1_ip} ${app_instance_2_ip}; do
  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ec2-user@$ip "
    sudo yum update -y
    sudo yum install -y wget tar gzip
    sudo useradd --no-create-home --shell /bin/false node_exporter || true
    cd /tmp
    wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
    tar -xzf node_exporter-1.7.0.linux-amd64.tar.gz
    sudo cp node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
    sudo chown node_exporter:node_exporter /usr/local/bin/node_exporter
    sudo cat > /etc/systemd/system/node_exporter.service <<'EXPORTER'
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter

Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EXPORTER
    sudo systemctl daemon-reload
    sudo systemctl enable node_exporter
    sudo systemctl start node_exporter
  " || echo "Failed to install node_exporter on $ip, retrying..."
done

echo "Monitoring stack setup complete!"
echo "Prometheus: http://${aws_instance.monitoring.public_ip}:9090"
echo "Grafana: http://${aws_instance.monitoring.public_ip}:3000 (admin/admin)"