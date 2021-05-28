# This file is part of r-parser. It is subject to the license terms in the COPYRIGHT file found in the top-level directory of this distribution and at https://raw.githubusercontent.com/lemonrock/r-parser/master/COPYRIGHT. No part of r-parser, including this file, may be copied, modified, propagated, or distributed except according to the terms contained in the COPYRIGHT file.
# Copyright © 2021 The developers of r-parser. See the COPYRIGHT file in the top-level directory of this distribution and at https://raw.githubusercontent.com/lemonrock/r-parser/master/COPYRIGHT.


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

# Changes path to `<root>/workspace/` if this is a multi-crate project
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
		mkdir -m 0700 -p "$vendored_sources_relative_folder_path"
	fi
}

local rust_toolchain_file_path
ensure_rust_toolchain_file_exists()
{
	rust_toolchain_file_path="$repository_root_folder_path"/rust-toolchain.toml
	exit_if_configuration_file_missing "$rust_toolchain_file_path"
}

ensure_rust_toolchain_installed()
{
	local channel="$(grep -m 1 '^channel' rust-toolchain | tr -d ' "' | awk -F= '{print $2}')"
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
	export PATH='/usr/local/bin:/usr/bin:/bin'
}

local build_profile_sh_file_path
local build_profile_toml_file_path
set_build_profile_file_without_extension_path()
{
	local target="$1"
	local cpu_profile="$2"

	local build_profile_file_without_extension_path="$build_profiles_folder_path"/"${target}.${cpu_profile}"
	
	build_profile_sh_file_path="${build_profile_file_without_extension_path}.sh"
	exit_if_configuration_file_missing "$build_profile_sh_file_path"
	
	build_profile_toml_file_path="${build_profile_file_without_extension_path}.toml"
	exit_if_configuration_file_missing "$build_profile_toml_file_path"
}

execute_command()
{
	/usr/bin/env -i PATH="$PATH" HOME="$HOME" TERM="$TERM" "$@"
}
	
execute_command_cargo_wrapper()
{
	local action="$1"
	shift 1
	
	execute_command "$cargo_tools_folder_path"/cargo-target-cpu-profile-wrapper "$build_profile_sh_file_path" "$action" "$target" "$cpu_profile" "$cargo_binary_path" -Zunstable-options -Zconfig-include --config "$build_profile_toml_file_path" "$action" --target "$target" "$@"
}

execute_command_with_heredoc()
{
	execute_command "$@" </dev/stdin
}

common_initialization()
{
	ensure_TERM_is_exported

	ensure_HOME_is_exported
	
	change_path_to_repository_root
	
	validate_cargo_workspace

	create_workspace_cargo_config_file_symlink_if_missing

	change_path_to_cargo_workspace
	
	ensure_vendored_sources_folder_path_exists
	
	ensure_rust_toolchain_file_exists
	
	# Must be called before changing the `PATH` environment variable in case `cargo` is on a non-standard `PATH`.
	set_cargo_paths

	ensure_PATH_is_exported
}

common_initialization "$@"
