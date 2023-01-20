from common_utils import update_md


def main():
    update_md('grpc_api/grpc_api.bal', 'grpc-api.md',
              'update-grpc-api', 'gRPC API')


main()
