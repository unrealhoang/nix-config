.PHONY: deploy-hanode

deploy-hanode:
	NIX_SSHOPTS="-i $(HOME)/.ssh/hanode -o IdentitiesOnly=yes" nixos-rebuild --flake .#hanode --target-host bing@home.bongbing.net --sudo switch
