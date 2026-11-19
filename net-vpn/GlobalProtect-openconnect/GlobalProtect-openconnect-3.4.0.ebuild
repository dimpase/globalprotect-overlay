# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.91.0"
inherit cargo desktop xdg

MY_P="${P,,}"
DESCRIPTION="GlobalProtect VPN command-line client with external-browser authentication"
HOMEPAGE="https://github.com/yuezk/GlobalProtect-openconnect"
# Upstream's offline bundle pins and vendors the Cargo.lock dependencies,
# including a Git dependency needed for workspace resolution.
SRC_URI="https://github.com/yuezk/GlobalProtect-openconnect/releases/download/v${PV}/${MY_P}.offline.tar.gz"
S="${WORKDIR}/${MY_P}"

LICENSE="GPL-3 GPL-2+ LGPL-2.1+"
LICENSE+=" Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD BSD-2
	ISC MIT MPL-2.0 Unicode-3.0 ZLIB"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

# This release requires upstream's modified OpenConnect API, built from the
# bundled sources. Its TLS and other C-library dependencies remain dynamic.
RDEPEND="
	app-crypt/p11-kit:=
	app-misc/ca-certificates
	dev-libs/gmp:=
	dev-libs/libxml2:2=
	dev-libs/nettle:=
	app-arch/lz4:=
	>=net-libs/gnutls-3.6:=
	sys-apps/iproute2
	x11-misc/xdg-utils
	virtual/zlib:=
"
DEPEND="${RDEPEND}
	test? ( dev-libs/openssl:= )"
BDEPEND="
	dev-build/autoconf
	dev-build/automake
	sys-devel/gettext
	dev-build/libtool
	virtual/pkgconfig
"

# OpenConnect probes this optional C11 function; glibc does not provide it.
QA_CONFIG_IMPL_DECL_SKIP=( memset_s )

src_unpack() {
	default
	cd "${S}" || die
	unpack ./vendor.tar.xz
	cargo_gen_config
}

src_prepare() {
	default
	# Use the installed Gentoo Rust toolchain and let Portage handle stripping.
	rm -f rust-toolchain.toml || die
	sed -i '/^strip = /d' Cargo.toml || die
}

src_configure() {
	# Disable the default embedded-webview feature in BOTH executables.
	cargo_src_configure --frozen --no-default-features -p gpclient -p gpauth
}

src_install() {
	dobin "$(cargo_target_dir)/gpclient" "$(cargo_target_dir)/gpauth"
	exeinto /usr/libexec/gpclient
	doexe packaging/files/usr/libexec/gpclient/vpnc-script
	# Only the browser callback handler is installed; there is no GUI app.
	domenu "${FILESDIR}/gpgui.desktop"
	dodoc README.md "${FILESDIR}/README.gentoo"
}
