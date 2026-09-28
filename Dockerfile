FROM mockoon/cli:latest
COPY mock-cupo-cartera.json /home/mockoon/data/mock.json
CMD ["--data", "/home/mockoon/data/mock.json", "--port", "10000"]