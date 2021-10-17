# This file is part of .cargo. It is subject to the license terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/lemonrock/.cargo/master/COPYRIGHT. No part of .cargo, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
# Copyright © 2021 The developers of .cargo. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/lemonrock/.cargo/master/COPYRIGHT.


exit_error_message()
{
	local exit_error_message="$1"
	printf "$exit_error_message\n" 1>&2
	exit 1
}

exit_if_folder_missing()
{
	local folder_path="$1"
	
	if [ ! -e "$folder_path" ]; then
		exit_error_message "folder $folder_path does not exist"
	fi
	if [ ! -r "$folder_path" ]; then
		exit_error_message "folder $folder_path is not readable"
	fi
	if [ ! -d "$folder_path" ]; then
		exit_error_message "folder $folder_path is not a folder"
	fi
	if [ ! -x "$folder_path" ]; then
		exit_error_message "folder $folder_path is not searchable"
	fi
}

exit_if_configuration_file_missing()
{
	local file_path="$1"
	
	if [ ! -e "$file_path" ]; then
		exit_error_message "configuration file $file_path does not exist"
	fi
	if [ ! -r "$file_path" ]; then
		exit_error_message "configuration file $file_path is not readable"
	fi
	if [ ! -f "$file_path" ]; then
		exit_error_message "configuration file $file_path is not a file"
	fi
	if [ ! -s "$file_path" ]; then
		exit_error_message "configuration file $file_path is empty"
	fi
}

exit_if_executable_with_absolute_path_is_missing()
{
	local executable_file_path="$1"
	
	if [ ! -e "$executable_file_path" ]; then
		exit_error_message "executable file $executable_file_path does not exist"
	fi
	if [ ! -r "$executable_file_path" ]; then
		exit_error_message "executable file $executable_file_path is not readable"
	fi
	if [ ! -f "$executable_file_path" ]; then
		exit_error_message "executable file $executable_file_path is not a file"
	fi
	if [ ! -s "$executable_file_path" ]; then
		exit_error_message "executable file $executable_file_path is empty"
	fi
	if [ ! -x "$executable_file_path" ]; then
		exit_error_message "executable file $executable_file_path is not executable"
	fi
}

exit_if_executables_are_not_on_PATH()
{
	local executable
	for executable in "$@"
	do
		set +e
			command -v "$executable" 1>/dev/null 2>/dev/null
			local exit_code=$?
		set -e
	
		if [ $exit_code -ne 0 ]; then
			exit_error_message "excutable $executable is not on the PATH $PATH"
		fi
	done
}

remove_folders_in_folder_if_it_exists()
{
	local folder_path="$1"
	shift 1
	
	local folder
	for folder in "$@"
	do
		local folder_path="$user_local_cargo_registry_folder_path"/"$folder"
		
		if [ -d "$folder_path" ]; then
			set +f
			local file
			for file in "$folder_path"/*
			do
				set -f
				if [ -e "$file" ]; then
					rm -rf "$file"
				fi
			done
		fi
		
		set -f
	done
}

# Changes path to `<root>/`.
local cargo_tools_folder_path
local repository_root_folder_path
local repository_root_dot_cargo_folder_path
local build_profiles_folder_path
change_path_to_repository_root()
{
	cargo_tools_folder_path="$(pwd)"
	
	cd ../.. 1>/dev/null 2>/dev/null
	
	repository_root_folder_path="$(pwd)"
	exit_if_folder_missing "$repository_root_folder_path"
	
	repository_root_dot_cargo_folder_path="$repository_root_folder_path"/.cargo
	exit_if_folder_missing "$repository_root_dot_cargo_folder_path"
	
	build_profiles_folder_path="$repository_root_dot_cargo_folder_path"/build-profiles
	exit_if_folder_missing "$build_profiles_folder_path"
}

local workspace_folder_path
local workspace_cargo_folder_path
validate_cargo_workspace()
{
	workspace_folder_path="$repository_root_folder_path"/workspace

	if [ ! -d "$workspace_folder_path" ]; then
		exit_error "These tools only currently support cargo projects using a workspace"
	fi
	exit_if_folder_missing "$workspace_folder_path"

	local workspace_folder_path="$repository_root_folder_path"/workspace
	exit_if_folder_missing "$workspace_folder_path"
	
	local workspace_cargo_toml_file_path="$workspace_folder_path"/Cargo.toml
	exit_if_configuration_file_missing "$workspace_cargo_toml_file_path"

	workspace_cargo_folder_path="$workspace_folder_path"/.cargo
	exit_if_folder_missing "$workspace_cargo_folder_path"
}

create_workspace_cargo_config_file_symlink_if_missing()
{
	local workspace_cargo_config_file_path="$workspace_cargo_folder_path"/config.toml
	
	local link='../../.cargo/cargo-vendor-sources.config.toml'
	if [ -L "$workspace_cargo_config_file_path" ]; then
		local actual="$(readlink "$workspace_cargo_config_file_path")"
		if [ "$actual" != "$link" ]; then
			exit_error_message "$workspace_cargo_config_file_path does not have value $link (it has the value $actual)"
		fi
		if [ ! -r "$workspace_cargo_config_file_path" ]; then
			exit_error_message "configuration file symlink $file_path is not readable"
		fi
		if [ ! -s "$workspace_cargo_config_file_path" ]; then
			exit_error_message "configuration file symlink $file_path is empty"
		fi
		
	else
		rm -rf "$workspace_cargo_config_file_path"
		ln -s "$link" "$workspace_cargo_config_file_path"
	fi
}

# Changes path to `<root>/workspace/` if this is a multi-crate project.
change_path_to_cargo_workspace()
{
	local workspace_cargo_config_file_path=""
	
	cd "$workspace_folder_path" 1>/dev/null 2>/dev/null
}

local cargo_binary_path
local user_local_cargo_folder_path
local user_local_cargo_registry_folder_path
local user_local_cargo_git_folder_path
set_cargo_paths()
{
	exit_if_executables_are_not_on_PATH cargo
	cargo_binary_path="$(command -v cargo)"
	
	user_local_cargo_folder_path="$HOME"/.cargo
	exit_if_folder_missing "$user_local_cargo_folder_path"
	
	user_local_cargo_registry_folder_path="$user_local_cargo_folder_path"/registry
	
	user_local_cargo_git_folder_path="$user_local_cargo_folder_path"/git
}

local vendored_sources_relative_folder_path
ensure_vendored_sources_folder_path_exists()
{
	vendored_sources_relative_folder_path=.cargo/vendored-sources

	if [ ! -d "$vendored_sources_relative_folder_path" ]; then
		execute_command mkdir -m 0700 -p "$vendored_sources_relative_folder_path"
	fi
}

local rust_toolchain_file_path
ensure_rust_toolchain_file_exists()
{
	rust_toolchain_file_path="$repository_root_folder_path"/rust-toolchain.toml
	exit_if_configuration_file_missing "$rust_toolchain_file_path"
}

ensure_HOME_is_exported()
{	
	if [ -z ${HOME+unset} ]; then
		cd ~ 1>/dev/null 2>/dev/null
			export HOME="$(pwd)"
		cd - 1>/dev/null 2>/dev/null
	fi
}

ensure_TERM_is_exported()
{
	if [ -z ${TERM+unset} ]; then
		export TERM='dumb'
	fi
}

ensure_PATH_is_exported()
{
	local folder_path
	local new_path=''
	for folder_path in '/usr/local/bin' '/usr/bin' '/bin'
	do
		exit_if_folder_missing "$folder_path"
		
		if [ -n "$new_path" ]; then
			new_path="${new_path}:"
		fi
		new_path="${new_path}${folder_path}"
	done
	
	export PATH="$new_path"
}

execute_command()
{
	PATH="$PATH" exit_if_executables_are_not_on_PATH "$1"
	exit_if_executable_with_absolute_path_is_missing /usr/bin/env
	/usr/bin/env -i PATH="$PATH" HOME="$HOME" TERM="$TERM" "$@"
}

local build_profiles_target_folder_path
local build_profile_toml_file_path
set_build_profile_file_without_extension_path()
{
	local target="$1"
	local cpu_profile="$2"
	
	build_profiles_target_folder_path="$build_profiles_folder_path"/"$target"
	exit_if_folder_missing "$build_profiles_target_folder_path"
	
	build_profile_toml_file_path="$build_profiles_target_folder_path"/"${cpu_profile}.toml"
	exit_if_configuration_file_missing "$build_profile_toml_file_path"
}

execute_command_cargo_wrapper()
{
	local action="$1"
	shift 1
	
	local build_profiles_target_folder_path="$build_profiles_folder_path"/"$target"
	exit_if_folder_missing "$build_profiles_target_folder_path"
		
	execute_command "$cargo_tools_folder_path"/cargo-target-cpu-profile-wrapper "$build_profiles_target_folder_path" "$action" "$target" "$cpu_profile" "$cargo_binary_path" -Zunstable-options -Zconfig-include --config "$build_profile_toml_file_path" "$action" --target "$target" "$@"
}

execute_command_with_heredoc()
{
	execute_command "$@" </dev/stdin
}

print_error_then_help()
{
	local message="$1"
	printf '%s\n' "$message" 1>&2
	
	print_help 1>&2
	exit 1
}

parse_arguments()
{
	case $# in
	
		0)
			print_error_then_help "Specify at least one argument"
		;;
		
		1)
			case "$1" in
				
				-h|-help|--help)
					print_help
					exit 0
				;;
				
				*)
					local target
					local cpu_profile
					local package_name="$1"
					
					detect_native_target_and_cpu_profile
					main_program
				;;
				
			esac
		;;
	
		2)
			print_error_then_help "Specify either one or three arguments"
		;;
	
		*)
			local target="$1"
			local cpu_profile="$2"
			local package_name="$3"
			
			shift 3
			main_program "$@"
		;;
	
	esac
}

detect_native_target_macos()
{
	local machine="$(execute_command uname -m)"
	case "$machine" in
		
		arm64)
			target='aarch64-apple-darwin'
		;;
		
		i386|i686)
			target='i686-apple-darwin'
		;;
		
		x86_64)
			target='x86_64-apple-darwin'
		;;
		
		'Power Macintosh')
			exit_unsupported "$machine is obsolete and will never be supported"
		;;
		
		*)
			exit_unsupported "Only 64-bit ARM and 64-bit Intel are supported on MacOS"
		;;
		
	esac
}

detect_musl_libc()
{
	local prefix="$1"
	local gnu_suffix="$2"
	local musl_suffix="$3"
	
	exit_if_executables_are_not_on_PATH ldd grep
	exit_if_executable_with_absolute_path_is_missing /bin/ls
	set +e
		ldd /bin/ls | grep -q 'musl'
		local exit_code=$?
	set -e
	
	if [ $exit_code -eq 0 ]; then
		local suffix="$musl_suffix"
	else
		local suffix="$gnu_suffix"
	fi
	
	target="${prefix}${suffix}"
}

detect_native_target_linux()
{
	local machine="$(execute_command uname -m)"
	case "$machine" in
		
		aarch64)
			detect_musl_libc 'aarch64-unknown-linux-' 'gnu' 'musl'
		;;
	
		aarch64_be)
			target='aarch64_be-unknown-linux-gnu'
		;;
	
		armv7l)
			# We do not actually detect uclibc
			detect_musl_libc 'aarch64-unknown-linux-' 'gnueabihf' 'musleabihf' 'uclibceabihf'
			#armv7-unknown-linux-gnueabi
			#armv7-unknown-linux-musleabi
			#thumbv7neon-unknown-linux-gnueabihf
		;;
	
		hexagon)
			target='hexagon-unknown-linux-musl'
		;;
	
		i686)
			detect_musl_libc 'i686-unknown-linux-' 'gnu' 'musl'
		;;
		
		m68k)
			target='m68k-unknown-linux-gnu'
		;;
		
		mips)
			# We do not actually detect uclibc
			detect_musl_libc 'mips-unknown-linux-' 'gnu' 'musl' 'uclibc'
			#mipsel-unknown-linux-gnu
			#mipsel-unknown-linux-musl
			#mipsel-unknown-linux-uclibc
		;;
		
		mips64)
			detect_musl_libc 'mips64-unknown-linux-' 'gnuabi64' 'muslabi64'
			#mips64el-unknown-linux-gnuabi64
			#mips64el-unknown-linux-muslabi64
		;;
		
		sparc)
			target='sparc-unknown-linux-gnu'
		;;
		
		sparc64)
			target='sparc64-unknown-linux-gnu'
		;;
		
		ppc)
			detect_musl_libc 'powerpc-unknown-linux-' 'gnu' 'musl'
		;;
		
		ppc64)
			detect_musl_libc 'powerpc64-unknown-linux-' 'gnu' 'musl'
		;;
			
		ppc64le)
			detect_musl_libc 'powerpc64le-unknown-linux-' 'gnu' 'musl'
		;;
		
		riscv)
			detect_musl_libc 'riscv32gc-unknown-linux-' 'gnu' 'musl'
		;;
		
		riscv64)
			detect_musl_libc 'riscv64gc-unknown-linux-' 'gnu' 'musl'
		;;
		
		s390x)
			target='s390x-unknown-linux-gnu'
		;;
		
		x86_32)
			target='x86_64-unknown-linux-gnux32'
		;;
		
		x86_64)
			detect_musl_libc 'x86_64-unknown-linux-' 'gnu' 'musl'
		;;
		
		armv8l|armv8b)
			exit_unsupported "ARM 64-bit architecture runnng as 32-bit such as $machine are not supported and probably never will be"
		;;

		armv7b)
			exit_unsupported "The ARM v7 big endian architecture is not supported and probably never will be"
		;;

		arm*)
			exit_unsupported "ARM v6 and earlier architectures such as $machine are not yet supported"
		;;
	
		arc|blackfin|c6x|cris|frv|h8300|ia64|k1om|m32r|metag|mn10300|parisc|parisc64|s390|score|sh64|unicore32)
			exit_unsupported "$machine is obsolete and will never be supported"
		;;
		
		alpha|openrisc|ppcle|sh|tile|xtensa)
			exit_unsupported "$machine is obscure, not supported by Rust and probably never will be"
		;;
		
		microblaze|nios2)
			exit_unsupported "$machine soft FPGA cores are not supported and probably never will be"
		;;
		
		*)
			exit_unsupported "$machine is unknown"
		;;
		
	esac
}

detect_native_target_and_cpu_profile()
{
	exit_unsupported()
	{
		local message="$1"
		
		printf '%s\n' "$message" 1>&2
		exit 1
	}

	cpu_profile=native
	
	local system="$(execute_command uname -s)"
	case "$system" in
		
		Darwin)
			detect_native_target_macos
		;;
		
		Linux)
			detect_native_target_linux
		;;
		
		DragonFly|FreeBSD|MidnightBSD|NetBSD|OpenBSD)
			exit_unsupported "The operating system $system is not supported yet for native TARGET and CPU_PROFILE detection"
		;;
		
		GNU|GNU/kFreeBSD|Haiku|Minix|QNX)
			exit_unsupported "The operating system $system is obscure and will probably never be supported for native TARGET and CPU_PROFILE detection"
		;;
		
		Windows_NT)
			exit_unsupported "BusyBox on Windows can never be supported for native TARGET and CPU_PROFILE detection"
		;;
		
		CYGWIN_NT-*|Interix|MINGW64_NT-*|MSYS_NT-*|UWIN-*)
			exit_unsupported "The compatibility layer $system is less useful with the advent of Windows Subsystem for Linux and will probably never be supported for native TARGET and CPU_PROFILE detection"
		;;
		
		AIX|HP-UX|IRIX|IRIX64|IS/WB|MINGW32_NT-*|MS-DOS|NONSTOP_KERNEL|OS/390|OS400|OSF1|ReliantUNIX-Y|SCO_SV|SINIX-Y|sn5176|SunOS|ULTRIX|UnixWare)
			exit_unsupported "The operating system $system is obselete and will never be supported for native TARGET and CPU_PROFILE detection"
		;;
		
		*)
			exit_unsupported "The operating system $system is unknown and will probably never be supported for native TARGET and CPU_PROFILE detection"
		;;
		
	esac
}

common_initialization()
{
	ensure_TERM_is_exported

	ensure_HOME_is_exported
	
	# Must be called before changing the `PATH` environment variable in case `cargo` is on a non-standard `PATH`.
	set_cargo_paths

	ensure_PATH_is_exported
	
	change_path_to_repository_root
	
	validate_cargo_workspace

	create_workspace_cargo_config_file_symlink_if_missing

	change_path_to_cargo_workspace
	
	ensure_vendored_sources_folder_path_exists
	
	ensure_rust_toolchain_file_exists
}

common_initialization "$@"
