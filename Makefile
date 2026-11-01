IDENTITY_NAME = local

reset-network:
	fuser -k 8000/tcp

initNetwork:
	icp network start -e local

initApp:
	./admin/local/deploy_local.sh

getMapping:
	icp canister call Factory handlerGetFullMapping '()' -e local --identity $(IDENTITY_NAME)

seeCanisterStatus:
	icp canister status 4zfnl-5t777-77775-aaadq-cai -e local --identity $(IDENTITY_NAME)