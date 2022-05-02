#!/bin/bash

## add private ips for master and worker nodes
sudo sed -i '/^127.0.0.1.*/a 10.0.0.5 k8smaster\n10.0.0.6 k8snode1\n10.0.0.7 k8snode2' /etc/hosts

## on all nodes setup containerd
cat << EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system

## install and configure containerd
sudo apt-get update && sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd

## on all nodes disable swap
sudo swapoff -a

## on all noed install kubeadm,kubelet and kubectl
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt-get update
sudo apt-get install -y kubelet=1.23.0-00 kubeadm=1.23.0-00 kubectl=1.23.0-00
sudo apt-mark hold kubelet kubeadm kubectl

## On the control plane node only, initialize the cluster and set up kubectl access.
sudo kubeadm init --pod-network-cidr 10.0.0.0/16 --kubernetes-version 1.23.0
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

## On control plane install Calico network add-on
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

## Get token to join workers to cluster
## kubeadm token create --print-join-command

## On workers join them using token
## sudo kubeadm join "token"
