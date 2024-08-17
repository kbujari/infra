CONTROLIP = 192.168.2.121

helm-bootstrap:
	@helm install prometheus-operator-crds \
		oci://ghcr.io/prometheus-community/charts/prometheus-operator-crds \
		--create-namespace \
		--namespace monitoring \
		--version 13.0.2

	@helm install cilium \
		cilium/cilium \
		--namespace kube-system \
		--version 1.16.0 \
		--values kubernetes/apps/kube-system/cilium/app/values.yaml

	@helm install spegel \
	 	oci://ghcr.io/spegel-org/helm-charts/spegel \
		--namespace kube-system \
		--version v0.0.23 \
		--values kubernetes/apps/kube-system/spegel/app/values.yaml

talos-gen:
	@talosctl gen config kube https://${CONTROLIP}:6443 \
		--config-patch-control-plane @kubernetes/talos/common.yaml \
		--output . \
		--force \
		--endpoints ${CONTROLIP} \

	@talosctl apply-config \
		--insecure \
		--file controlplane.yaml \
		--nodes ${CONTROLIP} \

	@mv -v talosconfig ~/.talos/config

talos-bootstrap:
	@talosctl config endpoint ${CONTROLIP}
	@talosctl config node ${CONTROLIP}
	@talosctl bootstrap

talos-kubeconfig:
	@talosctl kubeconfig ~/.kube/config --force

talos-reset:
	@talosctl reset \
		--graceful=false \
		--system-labels-to-wipe STATE \
		--system-labels-to-wipe EPHEMERAL \
		--reboot

flux-bootstrap:
	@kubectl apply --server-side --kustomize kubernetes/flux/bootstrap
	@kubectl apply --server-side --kustomize kubernetes/flux/config

clean:
	@rm -f controlplane.yaml worker.yaml talosconfig
