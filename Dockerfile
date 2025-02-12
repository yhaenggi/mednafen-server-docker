ARG ARCH
FROM gentoo/portage:latest AS portage

FROM gentoo/stage3:latest AS build
SHELL ["/bin/bash", "-c"]

ARG VERSION
ENV VERSION=${VERSION}

COPY --from=portage /var/db/repos/gentoo /var/db/repos/gentoo

COPY ./portage/make.conf /etc/portage/make.conf
COPY ./portage/package.accept_keywords /etc/portage/package.accept_keywords/

RUN mkdir -p /tmp/chroot

RUN echo "MAKEOPTS=-j$(($(nproc) / 2 + 1))" >> /etc/portage/make.conf
RUN echo "EMERGE_DEFAULT_OPTS=\"\${EMERGE_DEFAULT_OPTS} --jobs $(($(nproc) / 4 + 1))\"" >> /etc/portage/make.conf

# we dont want to rebuild the glibc/pam, build a binary package for the chroot
RUN quickpkg --include-config=y sys-libs/glibc
RUN quickpkg --include-config=y sys-libs/pam || true
RUN getuto
RUN emerge --nodeps --root /tmp/chroot --oneshot =games-server/mednafen-server-${VERSION}* sys-apps/busybox sys-libs/glibc sys-libs/pam

RUN /tmp/chroot/bin/busybox --install /tmp/chroot/usr/bin
RUN cp -av /etc/group /etc/shadow /etc/passwd /tmp/chroot/etc/

RUN mkdir -p /tmp/chroot/usr/lib/gcc && \
	cp -av /usr/lib/gcc/*/*/libgcc_s.so* /usr/lib/gcc/*/*/libstdc++.so* /tmp/chroot/usr/lib

RUN mkdir -p /tmp/chroot/home/mednafen && \
	bzcat /tmp/chroot/usr/share/doc/mednafen-server*/standard.conf*.bz2 > /tmp/chroot/home/mednafen/mednafen.conf

RUN rm -R /tmp/chroot/usr/share /tmp/chroot/var /tmp/chroot/usr/include

FROM scratch
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
SHELL ["/usr/bin/sh", "-c"]
COPY --from=build /tmp/chroot/ /

RUN ldconfig --verbose

RUN mkdir -p /home/mednafen && \
	addgroup -g 1000 mednafen && \
	adduser -G mednafen -u 1000 mednafen -D -s /usr/bin/sh && \
	chown -R mednafen:mednafen /home/mednafen


USER mednafen
WORKDIR /home/mednafen

EXPOSE 4046/tcp

ENTRYPOINT ["/usr/bin/sh"]
CMD ["-c", "/usr/bin/mednafen-server /home/mednafen/mednafen.conf"]

