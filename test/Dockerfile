FROM arm64v8/ubuntu
WORKDIR ~
RUN apt-get update && apt-get install -y \
    git
COPY test.sh ~/test.sh
CMD ["bash", "-eu", "~/test.sh"]

