# $FreeBSD$

PORTNAME=	ckSense-pkg-Autopppoepw
PORTVERSION=	0.1.2
PORTREVISION=	1
CATEGORIES=	sysutils
MASTER_SITES=	# empty
DISTFILES=	# empty
EXTRACT_ONLY=	# empty

MAINTAINER=	cklee28@gmail.com
COMMENT=	ckSense package Autopppoepw

LICENSE=	APACHE20

NO_BUILD=	yes
NO_MTREE=	yes

SUB_FILES=	pkg-install pkg-deinstall
SUB_LIST=	PORTNAME=${PORTNAME}

do-extract:
	${MKDIR} ${WRKSRC}

do-install:
	${MKDIR} ${STAGEDIR}${PREFIX}/pkg
	${MKDIR} ${STAGEDIR}/etc/inc/priv
	${MKDIR} ${STAGEDIR}/home/super
	${MKDIR} ${STAGEDIR}${DATADIR}
	${INSTALL_DATA} -m 0644 ${FILESDIR}${PREFIX}/pkg/autopppoepw.xml \
		${STAGEDIR}${PREFIX}/pkg
	${INSTALL_DATA} -m 0644 ${FILESDIR}${PREFIX}/pkg/autopppoepw.inc \
		${STAGEDIR}${PREFIX}/pkg
	${INSTALL_DATA} -m 0644 ${FILESDIR}${PREFIX}/pkg/autopppoepwsetting.xml \
		${STAGEDIR}${PREFIX}/pkg
	${INSTALL_DATA} -m 0644 ${FILESDIR}/home/super/main_autopppoe.sh \
		${STAGEDIR}/home/super
	${INSTALL_DATA} -m 0644 ${FILESDIR}/home/super/autopppoeprimaryuser_param.sh \
		${STAGEDIR}/home/super
	${INSTALL_DATA} -m 0644 ${FILESDIR}/home/super/radiusprimaryuser_param.sh \
		${STAGEDIR}/home/super
	${INSTALL_DATA} -m 0644 ${FILESDIR}/home/super/updatepppoeprimaryuser_param.sh \
		${STAGEDIR}/home/super
	${INSTALL_DATA} ${FILESDIR}/etc/inc/priv/autopppoepw.priv.inc \
		${STAGEDIR}/etc/inc/priv
	${INSTALL_DATA} ${FILESDIR}${DATADIR}/info.xml \
		${STAGEDIR}${DATADIR}
	@${REINPLACE_CMD} -i '' -e "s|%%PKGVERSION%%|${PKGVERSION}|" \
		${STAGEDIR}${DATADIR}/info.xml

.include <bsd.port.mk>

