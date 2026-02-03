//! ASCII art module for fetchz
//! Contains monochrome ASCII logos for various operating systems and distributions.

const std = @import("std");

pub const Logo = struct {
    art: []const []const u8,
    primary_color: Color,
    width: usize,
};

pub const Color = enum {
    black,
    red,
    green,
    yellow,
    blue,
    magenta,
    cyan,
    white,
    default,

    pub fn ansiCode(self: Color) []const u8 {
        return switch (self) {
            .black => "\x1b[30m",
            .red => "\x1b[31m",
            .green => "\x1b[32m",
            .yellow => "\x1b[33m",
            .blue => "\x1b[34m",
            .magenta => "\x1b[35m",
            .cyan => "\x1b[36m",
            .white => "\x1b[37m",
            .default => "\x1b[39m",
        };
    }

    pub fn boldCode(self: Color) []const u8 {
        return switch (self) {
            .black => "\x1b[1;30m",
            .red => "\x1b[1;31m",
            .green => "\x1b[1;32m",
            .yellow => "\x1b[1;33m",
            .blue => "\x1b[1;34m",
            .magenta => "\x1b[1;35m",
            .cyan => "\x1b[1;36m",
            .white => "\x1b[1;37m",
            .default => "\x1b[1;39m",
        };
    }
};

pub const reset = "\x1b[0m";
pub const bold = "\x1b[1m";
pub const dim = "\x1b[2m";

/// Get the appropriate logo for the OS/distribution
pub fn getLogo(os_name: []const u8) Logo {
    const lower = lowerFirst(os_name);

    if (containsAny(lower, &.{ "arch", "artix", "endeavour" })) {
        return arch_logo;
    } else if (containsAny(lower, &.{ "ubuntu", "kubuntu", "xubuntu", "lubuntu" })) {
        return ubuntu_logo;
    } else if (containsAny(lower, &.{"debian"})) {
        return debian_logo;
    } else if (containsAny(lower, &.{ "fedora", "nobara" })) {
        return fedora_logo;
    } else if (containsAny(lower, &.{ "macos", "darwin", "osx" })) {
        return macos_logo;
    } else if (containsAny(lower, &.{ "nixos", "nix" })) {
        return nixos_logo;
    } else if (containsAny(lower, &.{ "gentoo", "calculate" })) {
        return gentoo_logo;
    } else if (containsAny(lower, &.{ "opensuse", "suse", "tumbleweed", "leap" })) {
        return opensuse_logo;
    } else if (containsAny(lower, &.{ "manjaro", "garuda" })) {
        return manjaro_logo;
    } else if (containsAny(lower, &.{ "mint", "lmde" })) {
        return mint_logo;
    } else if (containsAny(lower, &.{ "pop", "pop_os", "pop!_os" })) {
        return pop_logo;
    } else if (containsAny(lower, &.{"void"})) {
        return void_logo;
    } else if (containsAny(lower, &.{ "alpine", "postmarket" })) {
        return alpine_logo;
    } else if (containsAny(lower, &.{"centos"})) {
        return centos_logo;
    } else if (containsAny(lower, &.{ "rhel", "red hat", "redhat" })) {
        return redhat_logo;
    } else if (containsAny(lower, &.{ "rocky", "alma" })) {
        return rocky_logo;
    } else if (containsAny(lower, &.{ "freebsd", "ghostbsd" })) {
        return freebsd_logo;
    } else if (containsAny(lower, &.{"openbsd"})) {
        return openbsd_logo;
    } else if (containsAny(lower, &.{"slackware"})) {
        return slackware_logo;
    } else if (containsAny(lower, &.{"kali"})) {
        return kali_logo;
    } else if (containsAny(lower, &.{"zorin"})) {
        return zorin_logo;
    } else if (containsAny(lower, &.{"elementary"})) {
        return elementary_logo;
    } else {
        return linux_logo;
    }
}

fn lowerFirst(s: []const u8) u8 {
    if (s.len == 0) return 0;
    const c = s[0];
    if (c >= 'A' and c <= 'Z') {
        return c + 32;
    }
    return c;
}

fn containsAny(first_char: u8, needles: []const []const u8) bool {
    for (needles) |needle| {
        if (needle.len > 0 and (needle[0] == first_char or needle[0] == first_char - 32)) {
            return true;
        }
    }
    return false;
}

/// Check if a string contains a substring (case insensitive for first char match)
pub fn containsIgnoreCase(haystack: []const u8, needle: []const u8) bool {
    if (needle.len > haystack.len) return false;
    var i: usize = 0;
    while (i + needle.len <= haystack.len) : (i += 1) {
        var matches = true;
        for (needle, 0..) |nc, j| {
            const hc = haystack[i + j];
            const nc_lower = if (nc >= 'A' and nc <= 'Z') nc + 32 else nc;
            const hc_lower = if (hc >= 'A' and hc <= 'Z') hc + 32 else hc;
            if (nc_lower != hc_lower) {
                matches = false;
                break;
            }
        }
        if (matches) return true;
    }
    return false;
}

/// Get logo based on full string matching
pub fn getLogoByName(os_name: []const u8) Logo {
    if (containsIgnoreCase(os_name, "arch") or containsIgnoreCase(os_name, "artix") or containsIgnoreCase(os_name, "endeavour")) {
        return arch_logo;
    } else if (containsIgnoreCase(os_name, "ubuntu")) {
        return ubuntu_logo;
    } else if (containsIgnoreCase(os_name, "debian")) {
        return debian_logo;
    } else if (containsIgnoreCase(os_name, "fedora") or containsIgnoreCase(os_name, "nobara")) {
        return fedora_logo;
    } else if (containsIgnoreCase(os_name, "macos") or containsIgnoreCase(os_name, "darwin") or containsIgnoreCase(os_name, "Mac OS")) {
        return macos_logo;
    } else if (containsIgnoreCase(os_name, "nixos")) {
        return nixos_logo;
    } else if (containsIgnoreCase(os_name, "gentoo")) {
        return gentoo_logo;
    } else if (containsIgnoreCase(os_name, "suse") or containsIgnoreCase(os_name, "tumbleweed")) {
        return opensuse_logo;
    } else if (containsIgnoreCase(os_name, "manjaro") or containsIgnoreCase(os_name, "garuda")) {
        return manjaro_logo;
    } else if (containsIgnoreCase(os_name, "mint")) {
        return mint_logo;
    } else if (containsIgnoreCase(os_name, "pop")) {
        return pop_logo;
    } else if (containsIgnoreCase(os_name, "void")) {
        return void_logo;
    } else if (containsIgnoreCase(os_name, "alpine")) {
        return alpine_logo;
    } else if (containsIgnoreCase(os_name, "centos")) {
        return centos_logo;
    } else if (containsIgnoreCase(os_name, "red hat") or containsIgnoreCase(os_name, "rhel")) {
        return redhat_logo;
    } else if (containsIgnoreCase(os_name, "rocky") or containsIgnoreCase(os_name, "alma")) {
        return rocky_logo;
    } else if (containsIgnoreCase(os_name, "freebsd")) {
        return freebsd_logo;
    } else if (containsIgnoreCase(os_name, "openbsd")) {
        return openbsd_logo;
    } else if (containsIgnoreCase(os_name, "slackware")) {
        return slackware_logo;
    } else if (containsIgnoreCase(os_name, "kali")) {
        return kali_logo;
    } else if (containsIgnoreCase(os_name, "zorin")) {
        return zorin_logo;
    } else if (containsIgnoreCase(os_name, "elementary")) {
        return elementary_logo;
    }
    return linux_logo;
}

// ============================================================================
// ASCII Art Definitions (Monochrome)
// ============================================================================

pub const linux_logo = Logo{
    .art = &.{
        "        _nnnn_        ",
        "       dGGGGMMb       ",
        "      @p~qp~~qMb      ",
        "      M|@||@) M|      ",
        "      @,----.JM|      ",
        "     JS^\\__/  qKL     ",
        "    dZP        qKRb   ",
        "   dZP          qKKb  ",
        "  fZP            SMMb ",
        "  HZM            MMMM ",
        "  FqM            MMMM ",
        "__| \".        |\\dS\"qML",
        "|    `.       | `' \\Zq",
        "_)      \\.___.,|     .'",
        "\\____   )MMMMMP|   .'  ",
        "     `-'       `--'    ",
    },
    .primary_color = .white,
    .width = 22,
};

pub const arch_logo = Logo{
    .art = &.{
        "        /\\          ",
        "       /  \\         ",
        "      /\\   \\        ",
        "     /      \\       ",
        "    /   ,,   \\      ",
        "   /   |  |  -\\     ",
        "  /_-''    ''-_\\    ",
    },
    .primary_color = .cyan,
    .width = 20,
};

pub const ubuntu_logo = Logo{
    .art = &.{
        "            .-/+oossssoo+/-.",
        "        `:+ssssssssssssssssss+:`",
        "      -+ssssssssssssssssssyyssss+-",
        "    .ossssssssssssssssss dMMMNy sssso.",
        "   /sssssssssss hdMMMMNy hMMMMs +sssss\\",
        "  +sssssssss hMMMMMMMMMN `MMMM+  ssssss+",
        " /ssssssssh MMMMMddddNMh  N MMN` sssssss\\",
        ".ssssssss dMMMN        `  `MMMy ssssssss.",
        "+ssss hMMMMy`             .NMN+ sssssss+",
        "osss dMMMMs               +NMM- ssssssso",
        "osss NMMMM                 mMMs ssssssso",
        "+sss+mMMMMy`              oNMM+ sssssss+",
        ".sssso`mMMMMs         ..yNMMN`sssssss.",
        " /sssss+ hNMMMN dddddNMMMN+ +sssssss\\",
        "  +ssssss+ `+mMMMMMMMN+  +sssssss+",
        "   /sssssss+. `:oo:. .+sssssss\\",
        "    .osssssssso+++++ossssssso.",
        "      -+sssssssssssssssss+-",
        "        `:+ssssssssss+:`",
        "            .-/++/-.",
    },
    .primary_color = .red,
    .width = 40,
};

pub const debian_logo = Logo{
    .art = &.{
        "       _,met$$$$$gg.       ",
        "    ,g$$$$$$$$$$$$$$$P.    ",
        "  ,g$$P\"         \"\"\"Y$$.\"  ",
        " ,$$P'               `$$$.  ",
        "',$$P       ,ggs.     `$$b: ",
        "`d$$'     ,$P\"'   .    $$$  ",
        " $$P      d$'     ,    $$P  ",
        " $$:      $$.   -    ,d$$'  ",
        " $$;      Y$b._   _,d$P'    ",
        " Y$$.    `.`\"Y$$$$P\"'       ",
        " `$$b      \"-.__            ",
        "  `Y$$                      ",
        "   `Y$$.                    ",
        "     `$$b.                  ",
        "       `Y$$b.               ",
        "          `\"Y$b._           ",
        "              `\"\"\"\"         ",
    },
    .primary_color = .red,
    .width = 28,
};

pub const fedora_logo = Logo{
    .art = &.{
        "             .',;::::;,'.",
        "         .';:cccccccccccc:;,.",
        "      .;cccccccccccccccccccccc;.",
        "    .:cccccccccccccccccccccccccc:.",
        "  .;ccccccccccccc;.:dddl:.;ccccccc;.",
        " .:ccccccccccccc;OWMKOOXMWd;ccccccc:.",
        ".:ccccccccccccc;KMMc;cc;xMMc;ccccccc:.",
        ",cccccccccccccc;MMM.;cc;;WW:;cccccccc,",
        ":cccccccccccccc;MMM.;cccccccccccccccc:",
        ":ccccccc;oxOOOo;MMM0teleraONMMd;ccccc:",
        "cccccc;0teleraONMMMMThere0tera;c;ccc;",
        "ccccc:dMMM:    ;MMM; OMMM0;::ccccccc:",
        "ccccc;WMMMd   .dMMM,,dMMMMdccccccccc;",
        ":cccc;MMMMMdddddNMMo.OMMM0cccccccccc:",
        ":cccc:OMMMMMMMMMMMMMWMM0cccccccccccc:",
        ".cccc:.,cdddddxxxddc::.cccccccccccc,",
        " :ccc:cccccccccccccccccccccccccccc;",
        "  .:cccccccccccccccccccccccccccc:.",
        "    .;:cccccccccccccccccccccc:;.",
        "       .,;:cccccccccccccc:;,.",
    },
    .primary_color = .blue,
    .width = 40,
};

pub const macos_logo = Logo{
    .art = &.{
        "        _nnnn_        ",
        "       dGGGGMMb       ",
        "      @p~qp~~qMb      ",
        "      M|@||@) M|      ",
        "      @,----.JM|      ",
        "     JS^\\__/  qKL     ",
        "    dZP        qKRb   ",
        "   dZP          qKKb  ",
        "  fZP            SMMb ",
        "  HZM            MMMM ",
        "  FqM            MMMM ",
        "__| \".        |\\dS\"qML",
        "|    `.       | `' \\Zq",
        "_)      \\.___.,|     .'",
        "\\____   )MMMMMP|   .'  ",
        "     `-'       `--'    ",
    },
    .primary_color = .white,
    .width = 32,
};

pub const nixos_logo = Logo{
    .art = &.{
        "    \\\\  \\\\ //     ",
        "   ==\\\\__\\\\/ //   ",
        "     //   \\\\//    ",
        "  ==//     //==   ",
        "   //\\\\___//      ",
        "  // /\\\\  \\\\==    ",
        "    // \\\\  \\\\     ",
    },
    .primary_color = .cyan,
    .width = 18,
};

pub const gentoo_logo = Logo{
    .art = &.{
        "     .-----.       ",
        "   .'       `.     ",
        "  /   _   _   \\    ",
        " |   O   O   |   ",
        " |  .-----.  |   ",
        "  \\  `---'  /    ",
        "   `.     .'     ",
        "     `---'       ",
    },
    .primary_color = .magenta,
    .width = 19,
};

pub const opensuse_logo = Logo{
    .art = &.{
        "              .;ldkO0000Okdl;.             ",
        "          .;d00LMKKKXKXWMMMMMMNx;.         ",
        "        .xNMMMMMMMMMMMMMMMMMMWKWWX.        ",
        "      .0MMMMMMWWXLLM00000000XMWM M0.       ",
        "     ;WMMMMMMMMMMXLMMMKK0KXMWMMMMK;        ",
        "    :KMMMMMMMMMMMMXLMMMMMMMMMMWWMMk        ",
        "   .NMMMMMMMMMMMMMMLMMMMMMM.......W.       ",
        "   ;WMMMMMMMMMWOol:'':cc;.MMMM ..X;        ",
        "   kMMM.oNWo,. .:lldk00d;. .. MMMM0        ",
        "   0MMM MKl .d0K00kkxkkO0Xd.  MMMMK        ",
        "   ;WMM Ol .0KNMM0xxkdxKWMXd. oMMMX        ",
        "    kMMWKd .;lOXOdlddxkXKMdl. .0MMX        ",
        "     oWMM:   .cd0Oxddxk0MK:.   cMMN        ",
        "      'OMMO.   .'cdkkkk:'.    .0MW'        ",
        "        .kWWX.             .xNMN.          ",
        "          .cKMWNK.      .ONMWO.            ",
        "             .:oKMMMWMMMN0l.               ",
    },
    .primary_color = .green,
    .width = 44,
};

pub const manjaro_logo = Logo{
    .art = &.{
        " ||||||||| ||||",
        " ||||||||| ||||",
        " ||||      ||||",
        " |||| |||| ||||",
        " |||| |||| ||||",
        " |||| |||| ||||",
        " |||| |||| ||||",
    },
    .primary_color = .green,
    .width = 15,
};

pub const mint_logo = Logo{
    .art = &.{
        "             ...-:::::-...             ",
        "          .-MMMMMMMMMMMMMMM-.          ",
        "       .-MMMM`..-::::::-..'MMMM-.      ",
        "     .:MMMM.:MMMMMMMMMMMMMMM:.MMMM:.   ",
        "    -MMM-M---MMMMMMMMMMMMMMMMMMM.MMM-  ",
        "   :MMM:MM`  :MMMM:....::-...-MMMM:MMM:",
        "   .MMM.MMMM`  :MM:`  ``    ``.MMMM.MMM.",
        "    :MMM:MMMM:   .:    ..     .:MMM MMMM:",
        "     MMM:MMMMM: .:...    ..   .:MMM MMMM ",
        "     :MMMMMMMMM:.:::::::::...:MMMMM MMM: ",
        "      MMMMMMMMMMMMMMMMMMMMMMMMMMM MMMM  ",
        "      :MMMMMMMMMMMMMMMMMMMMMMMMMM MMM:  ",
        "       MMMMMMMMMM:-'````':MMMMMM MMM    ",
        "        MMM:MMM:`          `:MMM:MMM    ",
        "         .MMMM.              .MMMM.     ",
    },
    .primary_color = .green,
    .width = 39,
};

pub const pop_logo = Logo{
    .art = &.{
        "             /////////////              ",
        "         /////////////////////          ",
        "      ///////*767teleraON//////         ",
        "    //////7teleraONMM7tele///////       ",
        "   /////teleraONMMMMMOtele////////      ",
        "  /////teleraONMMMMMMMOtele////////     ",
        " //////teleraONMMMMMMMOtele/////////    ",
        "////////teleraONMMMMMOtele//////////   ",
        "/////////teleraONMMMOtele///////////   ",
        "//////////teleraONMMOtele///////////   ",
        " /////////teleraONMOtele///////////    ",
        "  ////////teleraONOtele//////////      ",
        "   ///////*teleraOtele/////////        ",
        "    ////// tele ///////////            ",
        "      /////7tele//////                 ",
        "         ///////////                   ",
        "             /////                     ",
    },
    .primary_color = .cyan,
    .width = 41,
};

pub const void_logo = Logo{
    .art = &.{
        "                 _______              ",
        "    _ \\     __ \\ |     |              ",
        "    | |      | | |     |              ",
        "    | |      | | |_____|              ",
        "   _| |_     | |                      ",
        "  |_____|   _| |___                   ",
        "                                      ",
    },
    .primary_color = .green,
    .width = 38,
};

pub const alpine_logo = Logo{
    .art = &.{
        "       .hddddddddddddddddddddddh.      ",
        "      :dddddddddddddddddddddddddd:     ",
        "     /dddddddddddddddddddddddddddd/    ",
        "    +dddddddddddddddddddddddddddddd+   ",
        "  `sdddddddddddddddddddddddddddddddds` ",
        " `ydddddddddddd++hdddddddddddddddddddy`",
        ".hddddddddddd+`   `+ddddh:-sdddddddddh.",
        "hdddddddddd+`       `+y:   `sddddddddddh",
        "ddddddddh+`         `//`      `+hdddddddd",
        "ddddddh+`         `/hddh/`      `+hdddddd",
        ":ddddd:`        `/hdddddddh/`     `:ddddd:",
        " .yddd/       ./hddddddddddddh/.   /dddy. ",
        "  `sddd:    ./ydddddddddddddddddy/.:ddds` ",
        "   `yddd:-:ydddddddddddddddddddddddddy`   ",
        "     `+dddddddddddddddddddddddddddd+`     ",
        "       `+dddddddddddddddddddddddd+`       ",
        "          `+dddddddddddddddddd+`          ",
    },
    .primary_color = .blue,
    .width = 38,
};

pub const centos_logo = Logo{
    .art = &.{
        "                 ..                 ",
        "               .PLTJ.               ",
        "              <><><><>              ",
        "     GY:///// MEDSTJT ///// NF      ",
        "     <><><><><><><><><><><><>       ",
        "    MMMMMMMMMMMMMMMMMMMMMMMMM       ",
        "              <>    <>              ",
        " >      <>  <>    <>   <>  <>       ",
        "     <>      <> <> <>    <>         ",
        " >  <>       <> <> <>      <>       ",
        " >      <>    <>   <>  <>           ",
        "              <>    <>              ",
        "     VLM::///// / / //:://OTEZ      ",
        "                 ..                 ",
    },
    .primary_color = .magenta,
    .width = 36,
};

pub const redhat_logo = Logo{
    .art = &.{
        "            .MMM..:MMMMMMM          ",
        "           MMMMMMMMMMMMMMMMMM       ",
        "           MMMMMMMMMMMMMMMMMMMM.    ",
        "          MMMMMMMMMMMMMMMMMMMMMM    ",
        "         ,MMMMMMMMMMMMMMMMMMMMMM:   ",
        "         MMMMMMMMMMMMMMMMMMMMMMMM   ",
        "   .MMMM  MMMMMMMMMMMMMMMMMMMMMMMM  ",
        "  MMMMMM    `MMMMMMMMMMMMMMMMMMMM   ",
        " MMMMMMMM      MMMMMMMMMMMMMMMMM    ",
        "MMMMMMMMM.       `MMMMMMMMMMMMMM    ",
        "MMMMMMMMMMM.                        ",
        "`MMMMMMMMMMMMM.                     ",
        " `MMMMMMMMMMMMMMMMM.                ",
        "    MMMMMMMMMMMMMMMMMM              ",
        "      `\"MMMMMMMMMMMM                ",
        "          `\"MMMMMMM                 ",
    },
    .primary_color = .red,
    .width = 36,
};

pub const rocky_logo = Logo{
    .art = &.{
        "        `-/+++++++++/-.`          ",
        "     `-+++++++++++++++++-`        ",
        "    .+++++++++++++++++++++.       ",
        "   -+++++++++++++++++++++++.      ",
        "  :+++++++++++++++++++++++++:     ",
        "  ++++++++++++++++++++++++++++    ",
        " `++++++++++++++++++++++++++++'   ",
        " .++++++++++++++++++++++++++++++  ",
        " +++++++++++++++++++++++++++++++: ",
        " ++++++++++++++++++++++++++++++++ ",
        " `++++++++++++++++++++++++++++++' ",
        "  +++++++++++++++++++++++++++++'  ",
        "   `++++++++++++++++++++++++++'   ",
        "     `-+++++++++++++++++++++-`    ",
        "        `.-/+++++++++++/-.`       ",
    },
    .primary_color = .green,
    .width = 35,
};

pub const freebsd_logo = Logo{
    .art = &.{
        "   ```                        `    ",
        "  s` `.....---......---.....--`  ' ",
        "  +o   .--`         /y:`      +.   ",
        "   yo`:.            :o      `+-    ",
        "    y/               -/`   -o/     ",
        "   .-                  ::/sy+:.    ",
        "   /                     `--  /    ",
        "  `:                          :`   ",
        "  `:                          :`   ",
        "   /                          /    ",
        "   .-                        -.    ",
        "    --                      -.     ",
        "     `:`                  `:`      ",
        "       .--            `--.         ",
        "          .googoole.:              ",
    },
    .primary_color = .red,
    .width = 36,
};

pub const openbsd_logo = Logo{
    .art = &.{
        "                                       _  ",
        "                                      (_) ",
        "               |    .                     ",
        "           .   |L  /|   .                 ",
        "       _ . |\\ _| \\--+._/| .               ",
        "      / ||\\| Y J  )   / |/| ./            ",
        "     J  |)'( |        ` F`.'/             ",
        "   -<|  F         __     .-<              ",
        "     | /       .-'. `.  /-. L___          ",
        "     J \\      <    \\  | | O.-|            ",
        "   _J \\  .-    \\/ O | |   \\ |F            ",
        "  '-F  -<_.     \\   .-'  `-' L__          ",
        " __J  _   _.     >-'  )._.   |-'          ",
        " `-|.'   /_.          \\_|   F              ",
        "   /.-   .                _.<             ",
        "  /'    /.'             .'  `\\            ",
        "   /L  /'   |/      _.-'-\\               ",
        "  /'J       ___.---'\\|                   ",
        "    |\\  .--' V  | `. `                   ",
        "    |/`. `-.     `._)                     ",
        "       / .-.\\                             ",
        "       \\ (  `\\                           ",
        "        `.\\                               ",
    },
    .primary_color = .yellow,
    .width = 43,
};

pub const slackware_logo = Logo{
    .art = &.{
        "                  :::::::::::::::::::  ",
        "             ::::::::::::::::::::::::: ",
        "          ::::::::cllcccccllllllll:::::::",
        "       :::::::::lc               dc:::::::",
        "      ::::::::cl   clllccllll    oc:::::::::",
        "     :::::::::o   lc::::::::co   oc::::::::::",
        "    ::::::::::o    cccclc:::::clcc:::::::::::",
        "    :::::::::::lc        cclccclc::::::::::::",
        "   ::::::::::::::lcclcc          lc::::::::::",
        "   ::::::::::cclcc:::::lccclc     oc:::::::::",
        "   ::::::::::o    l::::::::::l    oc:::::::::",
        "    :::::cll:o     clcllcccll     o:::::::::::",
        "    :::::occ:o                  clc:::::::::::",
        "     ::::ocl:ccslclccclclccclclc::::::::::::",
        "      :::oclcccccccccccccllllllllllllll::",
        "       ::lcc1teleraONMMMMMMMc]0lcclll::",
        "          :::::::::::::::::::::::::::::",
        "            :::::::::::::::::::::::::::",
        "               :::::::::::::::::::::::",
    },
    .primary_color = .blue,
    .width = 41,
};

pub const kali_logo = Logo{
    .art = &.{
        "      ,.....                              ",
        "  ----`     `..,;:ccc,.                   ",
        "           ......''';lxO.                 ",
        " .....''''..googoole.;;..:oo,...          ",
        "            google.;;......googool        ",
        "          ....googool:.oo:oo             ",
        "                 .oogooo'......',googoo;  ",
        "                     .googol...........,oo",
        "                        ......',googoo;oo ",
        "                                ....googl ",
        "                                    :o.   ",
    },
    .primary_color = .blue,
    .width = 43,
};

pub const zorin_logo = Logo{
    .art = &.{
        "        `osssssssssssssssssssso`         ",
        "       .osssssssssssssssssssssso.        ",
        "      .+oooooooooooooooooooooooo+.       ",
        "                                         ",
        " `+++++++++++++++++. .++++++++++++++++++`",
        " /sssssssssssssssss` `sssssssssssssssss/ ",
        " /sssssssssssssssss` `sssssssssssssssss/ ",
        " /sssssssssssssssss` `sssssssssssssssss/ ",
        " /sssssssssssssssss` `sssssssssssssssss/ ",
        " /sssssssssssssssss` `sssssssssssssssss/ ",
        " /sssssssssssssssss` `sssssssssssssssss/ ",
        "                                         ",
        "      .+oooooooooooooooooooooooo+.       ",
        "       .osssssssssssssssssssssso.        ",
        "        `osssssssssssssssssssso`         ",
    },
    .primary_color = .blue,
    .width = 41,
};

pub const elementary_logo = Logo{
    .art = &.{
        "          eeeeeeeeeeeeeeeee            ",
        "       eeeeeeeeeeeeeeeeeeeeeee         ",
        "     eeeee  eeeeeeeeeeee   eeeee       ",
        "   eeee   eeeee       eee     eeee     ",
        "  eeee   eeee          eee     eeee    ",
        " eee    eee            eee       eee   ",
        " eee   eee            eee        eee   ",
        "ee     eee           eeee         ee   ",
        "ee     eee         eeeee          ee   ",
        "ee     eeeee     eeeee            ee   ",
        " eee     eeeeeeeeeee             eee   ",
        " eee      eeeeee                eee    ",
        "  eeee                         eeee    ",
        "   eeee                       eeee     ",
        "     eeeee                 eeeee       ",
        "       eeeeeeeeeeeeeeeeeeeeeee         ",
        "          eeeeeeeeeeeeeeeee            ",
    },
    .primary_color = .cyan,
    .width = 38,
};
