dnl
dnl Given an argname, return the argument type code or 'generic'
dnl If strict is not blank, raise an error if there is not a type code stored
dnl
dnl $1: argname
dnl $2: strict
m4_define([_GET_VALUE_TYPE], [m4_do(
	[m4_ifdef([$1_VAL_TYPE], [m4_indir([$1_VAL_TYPE])],
		[m4_ifnblank([$2], [m4_fatal([There is no type defined for argument '$1'.])], [generic])])],
)])


dnl
dnl $1: The value type string (code)
dnl $2: The type group name (optional, try to infer from value type)
dnl $3: Concerned arguments (as a list)
dnl TODO: Integrate with help (and not only with the help synopsis)
dnl TODO: Validate the type value (code) string
argbash_api([ARG_TYPE_GROUP], [m4_do(
	[[$0($@)]],
	[m4_ifblank([$2], [m4_fatal([Name inference not implemented yet])])],
	[_TYPED_GROUP_STUFF([$1], m4_dquote(m4_default([$2], [???])), [$3])],
)])


dnl
dnl $1: The value type string (code)
dnl $2: The type group name
dnl $3: Concerned arguments (as a list)
dnl $4: The set of possible values (as a list)
dnl $5: The index variable suffix
dnl TODO: Integrate with help (and not only with the help synopsis)
argbash_api([ARG_TYPE_GROUP_SET], [m4_do(
	[[$0($@)]],
	[m4_foreach([_val], [$4], [m4_do(
		[m4_list_append([_LIST_$1_QUOTED], m4_quote(_sh_quote_also_blanks(m4_quote(_val))))],
		[m4_list_append([_LIST_$1], m4_quote(_val))],
	)])],
	[_define_validator([$1], m4_expand([_MK_VALIDATE_GROUP_FUNCTION([$1], [$5])]),
		m4_expand([[one of ]m4_list_join([_LIST_$1], [, ], ', ', [ and ])]))],
	[m4_foreach([_argname], [$3], [m4_do(
		[m4_list_contains([_ARGS_LONG], _argname, ,
				[m4_fatal('_argname' [is not a script argument.])])],
		[m4_set_add([GROUP_ARGS], m4_quote(_argname))],
		[m4_define([_]m4_quote(_argname)[_SUFFIX], [[$5]])],
	)])],
	[_TYPED_GROUP_STUFF([$1], [$2], [$3])],
)])


dnl
dnl The common stuff to perform when adding a typed group
dnl Registers the argument-type pair to be retreived by _GET_VALUE_TYPE or _GET_VALUE_STR
dnl $1: The value type
dnl $2: The type group name (NOT optional)
dnl $3: Concerned arguments (as a list)
m4_define([_TYPED_GROUP_STUFF], [m4_do(
	[m4_set_contains([VALUE_TYPES], [$1], , [m4_fatal([The type '$1' is unknown.])])],
	[m4_set_add([VALUE_TYPES_USED], [$1])],
	[m4_set_contains([VALUE_GROUPS], [$2], [m4_fatal([Value group $2 already exists!])])],
	[m4_set_add([VALUE_GROUPS], [$2])],
	[m4_foreach([_argname], m4_dquote($3), [m4_do(
		[dnl TODO: Test that vvv this check vvv works
],
		[m4_set_contains([TYPED_ARGS], _argname,
			[m4_fatal([Argument ]_argname[ already has a type ](_GET_VALUE_TYPE(_argname, 1))!)])],
		[m4_set_add([VALUE_GROUP_$1], _argname)],
		[m4_set_add([TYPED_ARGS], _argname)],
		[m4_define(_argname[_VAL_TYPE], [[$1]])],
		[m4_define(_argname[_VAL_GROUP], [[$2]])],
	)])],
	[m4_define([$2_VALIDATOR], [[_validator_$1]])],
)])


dnl
dnl For all arguments we know that are typed, re-assign their values using the validator function, e.g.
dnl arg_val=$(validate $arg_val argument-name) || exit 1
dnl Remarks:
dnl  - The argument name misses -- if it is an optional argument, because we don't know what type of arg this is
dnl  - The subshell won't propagate the die call, so that's why we have to exit "manually"
dnl  - Validator is not only a validator - it is a cannonizer.
dnl  - The type 'string' does not undergo validation
m4_define([_VALIDATE_POSITIONAL_ARGUMENTS], [m4_do(
	[m4_set_empty([TYPED_ARGS], , [# Validation of values
])],
	[dnl Don't do anything if we are string
],
	[m4_lists_foreach_positional([_ARGS_LONG], [_arg], [m4_set_contains([TYPED_ARGS], _arg, [m4_do(

		[m4_pushdef([_arg_varname], [_varname(_arg)])],
		
		[_arg_varname=_MAYBE_VALIDATE_VALUE(_arg, "$_arg_varname") || exit 1
],
		[m4_popdef([_arg_varname])],
	)])])],
)])


m4_define([_IF_ARG_IS_TYPED], [m4_set_contains([TYPED_ARGS], [$1], [$2], [$3])])


m4_define([_MAYBE_ASSIGN_INDICES_TO_TYPED_SINGLE_VALUED_ARGS], [m4_do(
	[m4_set_foreach([GROUP_ARGS], [_arg], [m4_do(
		[_CATH_IS_SINGLE_VALUED(m4_list_nth([_ARGS_CATH], m4_list_indices([_ARGS_LONG], _arg), 123),
			[_VALIDATE_VALUES_IDX(_arg, m4_indir([_]_arg[_SUFFIX]))
],
			[])],
	)])],
)])


dnl
dnl Assign a validation of a value of a certain type to a variable.
dnl Does nothing if the type is string or the value doesn't have a type
dnl
dnl $1: The associated argument name
dnl $2: The variable holding the value to be validated (with quoting, e.g. "$value")
m4_define([_MAYBE_VALIDATE_VALUE], [m4_case(_GET_VALUE_TYPE([$1]),
		[string], [[$2]],
		[generic], [[$2]],
		[m4_do(
			["$(],
			[_GET_VALUE_TYPE([$1], 1)],
			[ [$2] "[$1]")"],
)])])


dnl
dnl $1: argname
dnl $2: suffix
m4_define([_VALIDATE_VALUES_IDX], [m4_ifnblank([$2], [m4_do(
	[_varname([$1])[_$2="@S|@@{:@]],
	[_GET_VALUE_TYPE([$1], 1)],
	[ "$_varname([$1])" "[$1]" idx@:}@"],
)])])
