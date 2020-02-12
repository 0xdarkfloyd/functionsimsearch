FROM bitnami/minideb:buster as builder

RUN chmod 777 /tmp
RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y git wget cmake sudo gcc-7 g++-7 python3-pip zlib1g-dev googletest
RUN apt-get install -y libgtest-dev libgflags-dev libz-dev libelf-dev g++ python3-pip libboost-system-dev libboost-thread-dev libboost-date-time-dev

RUN mkdir /code

# build functionsimsearch
RUN cd /code && \
    git clone https://github.com/thomasdullien/functionsimsearch.git && \
    cd functionsimsearch && \
    chmod +x ./build_dependencies.sh && \
    ./build_dependencies.sh && \
    make -j 15

RUN strip /code/functionsimsearch/bin/*
RUN cd /code && strip $(find -iname \*.so)

FROM bitnami/minideb:buster

COPY --from=builder /code/functionsimsearch/third_party/dyninst-9.3.2/stackwalk/libstackwalk.so.9.3.2 /usr/local/lib/
COPY --from=builder /code/functionsimsearch/third_party/dyninst-9.3.2/common/libcommon.so.9.3.2 /usr/local/lib/
COPY --from=builder /code/functionsimsearch/third_party/dyninst-9.3.2/parseAPI/libparseAPI.so.9.3.2 /usr/local/lib/
COPY --from=builder /code/functionsimsearch/third_party/dyninst-9.3.2/symlite/libsymLite.so.9.3.2 /usr/local/lib/
COPY --from=builder /code/functionsimsearch/third_party/dyninst-9.3.2/symtabAPI/libsymtabAPI.so.9.3.2 /usr/local/lib/
COPY --from=builder /code/functionsimsearch/third_party/dyninst-9.3.2/elf/libdynElf.so.9.3.2 /usr/local/lib/
COPY --from=builder /code/functionsimsearch/third_party/dyninst-9.3.2/dwarf/libdynDwarf.so.9.3.2 /usr/local/lib/
COPY --from=builder /code/functionsimsearch/third_party/dyninst-9.3.2/proccontrol/libpcontrol.so.9.3.2 /usr/local/lib/
COPY --from=builder /code/functionsimsearch/third_party/dyninst-9.3.2/instructionAPI/libinstructionAPI.so.9.3.2 /usr/local/lib/
COPY --from=builder /code/functionsimsearch/third_party/dyninst-9.3.2/dynC_API/libdynC_API.so.9.3.2 /usr/local/lib/
COPY --from=builder /code/functionsimsearch/third_party/dyninst-9.3.2/libdwarf/lib/libdwarf.so /usr/local/lib/
COPY --from=builder /code/functionsimsearch/third_party/dyninst-9.3.2/patchAPI/libpatchAPI.so.9.3.2 /usr/local/lib/
COPY --from=builder /code/functionsimsearch/third_party/dyninst-9.3.2/dyninstAPI_RT/libdyninstAPI_RT.so.9.3.2 /usr/local/lib/
COPY --from=builder /code/functionsimsearch/third_party/dyninst-9.3.2/dyninstAPI/libdyninstAPI.so.9.3.2 /usr/local/lib/
COPY --from=builder /code/functionsimsearch/third_party/dyninst-9.3.2/boost/src/boost/stage/lib/libboost_date_time-mt.so* /usr/local/lib/
COPY --from=builder /code/functionsimsearch/third_party/dyninst-9.3.2/boost/src/boost/stage/lib/libboost_thread-mt.so* /usr/local/lib/
COPY --from=builder /code/functionsimsearch/third_party/dyninst-9.3.2/boost/src/boost/stage/lib/libboost_system-mt.so* /usr/local/lib/
COPY --from=builder /code/functionsimsearch/third_party/spii/lib/libspii.so* /usr/local/lib/
RUN mkdir -p /code/functionsimsearch
COPY --from=builder /code/functionsimsearch/bin /code/functionsimsearch/bin
COPY --from=builder /code/functionsimsearch/entrypoint.sh /code/functionsimsearch/
RUN ldconfig
RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y libelf-dev libgflags-dev libz-dev libboost-system1.67.0 libboost-thread1.67.0 libboost-date-time1.67.0 libboost-filesystem1.67.0 libgomp1
 

# dispatch via entrypoint script
# recommend mapping the /pwd volume, probably like (for ELF file):
#
#    docker run -it --rm -v $(pwd):/pwd functionsimsearch disassemble ELF /pwd/someexe
VOLUME /pwd
WORKDIR /code/functionsimsearch
RUN chmod +x /code/functionsimsearch/entrypoint.sh
ENTRYPOINT ["/code/functionsimsearch/entrypoint.sh"]
