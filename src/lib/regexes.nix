rec {
  ftype = "(runtime|app)";
  fref = "[a-zA-Z0-9._-]+";
  farch = "[0-9x_a-zA-Z-]*";
  fbranch = "[a-zA-Z0-9.-]+";
  fcommit = "[a-z0-9]{64}";
  ffile = "\.flatpak(ref)?";

  fpkgnet = "${fremote}:${ftype}\/${fref}\/${farch}\/${fbranch}(:${fcommit})?";
  fpkglocal = "(${fremote})?:.+${ffile}";

  fremote = "[A-Za-z0-9-]+";
  fpkg = "${fpkgnet}|${fpkglocal}";
}