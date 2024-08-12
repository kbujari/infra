CONTROLIP = 192.168.2.121

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

cilium-bootstrap:
	@helm install \
		cilium \
		cilium/cilium \
		--version 1.16.0 \
		--namespace kube-system \
		--values kubernetes/apps/kube-system/cilium/app/values.yaml

clean:
	@rm -f controlplane.yaml worker.yaml talosconfig
