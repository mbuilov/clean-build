syn match     cFunction       /[_a-zA-Z][_a-zA-Z0-9_]*[ \t\n\r]*(/ms=s,me=e-1
syn match     cUserType       /[_a-zA-Z][_a-zA-Z0-9_]*\(_t\|_ref\|_cref\)[* \t\n\r),;]/ms=s,me=e-1
syn match     cStructObject   /\./
syn match     cAddrExpr       /*\|&\||/
syn match     cAssert         /\<ASSERT\>\|\<assert\>/
syn match     cDbgPrint       /DBGPRINT/
syn match     _Annotation_    /\<_[A-Z][_a-z]*_\>/
syn match     cOper           /<\|>\|!/
syn match     cUnOper         /+\|-/
syn match     assignment      /=\|&=\||=\|\^=\|\*=\|\/=\|%=\|+=\|-=\|++\|--/
syn match     cConditionalOp  /==\|!=\|<=\|>=\|&&\|||\|\~/
syn match     cStructObjectPtr /->/
syn match     bracket         /(\|)\|\[\|\]/
syn match     endcolon        /;/
syn match     opcolons        /,\|:\|?/
syn match     bodyBracket     /{\|}/
syn match     trailingSpaces  /[ \t][ \t]*$/
syn keyword	  cGoto           goto
"syn match     vartype         /[{;][ \t\n\r]*\zs[_a-zA-Z][_a-zA-Z0-9_]*\ze[* \t\n\r]\+[_a-zA-Z][_a-zA-Z0-9_]*\([ \t\n\r]*,[* \t\n\r]*[_a-zA-Z][_a-zA-Z0-9_]*\)*;/
"syn match     vartype         /[{;][ \t\n\r]*[_a-zA-Z][_a-zA-Z0-9_]*\ze[* \t\n\r]\+[_a-zA-Z][_a-zA-Z0-9_]*/ms=s,me=e-1
"syn match     typeidentifier  /[_a-zA-Z][_a-zA-Z0-9_]*/ contained
"syn region    argfntype       start=/[_a-zA-Z][_a-zA-Z0-9_]*[ \t\n\r]\+/ end=/[;,(]/ transparent contains=typeidentifier

hi def link cConditionalOp Operator
hi def link cUnOper Operator
hi def link cAddrExpr cRepeat
hi def link cOper keyword
hi def link assignment keyword
"hi def link vartype cUserType
"hi def link argfntype cUserType

syn match     __attribute__   /((warn_unused_result))\|((returns_nonnull))\|((noreturn))\|((const))\|((pure))\|((always_inline))\|((noinline))/
syn keyword   __attribute__   __forceinline __declspec __attribute__ __format__  __printf__

syn match     _Ms_annotation_unknown_ /\<_[A-Z][_a-z]*_\>/

syn keyword   _Ms_annotation_ _Curr_ _Old_ _In_ _In_opt_ _In_z_ _In_opt_z_ _Inout_ _Inout_opt_ _Inout_z_ _Inout_opt_z_ _Out_ _Out_opt_ _Outptr_ _Outptr_opt_ _Outptr_result_maybenull_ _Outptr_opt_result_maybenull_ _Outptr_result_z_ _Outptr_opt_result_z_ _Outptr_result_maybenull_z_ _Outptr_opt_result_maybenull_z_ _In_reads_ _In_reads_opt_ _In_reads_bytes_ _In_reads_bytes_opt_ _In_reads_to_ptr_ _In_reads_to_ptr_opt_ _Inout_updates_ _Inout_updates_opt_ _Inout_updates_bytes_ _Inout_updates_bytes_opt_ _Inout_updates_to_ _Inout_updates_to_opt_ _Inout_updates_all_ _Inout_updates_all_opt_ _Inout_updates_bytes_to_ _Inout_updates_bytes_to_opt_ _Inout_updates_bytes_all_ _Inout_updates_bytes_all_opt_ _Out_writes_ _Out_writes_opt_ _Out_writes_bytes_ _Out_writes_bytes_opt_ _Out_writes_to_ptr_ _Out_writes_to_ptr_opt_ _Out_writes_to_ _Out_writes_to_opt_ _Out_writes_all_ _Out_writes_all_opt_ _Out_writes_bytes_to_ _Out_writes_bytes_to_opt_ _Out_writes_bytes_all_ _Out_writes_bytes_all_opt_ _Ret_null_ _Ret_writes_ _Ret_writes_z_ _Ret_writes_bytes_ _Ret_writes_maybenull_ _Ret_writes_maybenull_z_ _Ret_writes_bytes_maybenull_ _Ret_writes_to_ _Ret_writes_bytes_to_ _Ret_writes_to_maybenull_ _Ret_writes_bytes_to_maybenull_

syn keyword   _Ms_annotation_ _Ret_null_ _Ret_notnull_ _Ret_maybenull_ _Ret_z_ _Ret_maybenull_z_ _Ret_valid_ _Ret_opt_valid_ _Must_inspect_result_ _In_range_ _Out_range_ _Ret_range_ _Deref_in_range_ _Deref_out_range_ _Deref_ret_range_ _Pre_equal_to_ _Post_equal_to_ _Pre_satisfies_ _Post_satisfies_ _Success_ _Return_type_success_ _Result_nullonfailure_ _Result_zeroonfailure_ _Outptr_result_nullonfailure_ _Outptr_opt_result_nullonfailure_ _Printf_format_string_ _Group_ _On_failure_ _Always_ _At_ _When_ _Post_z_ _Post_ptr_invalid_ _Post_valid_ _Post_invalid_ _Post_null_ _Post_notnull_ _Post_maybenull_ _Pre_valid_ _Pre_opt_valid_ _Pre_invalid_ _Pre_unknown_ _Pre_notnull_ _Pre_maybenull_ _Pre_null_ _Use_decl_annotations_ _Check_return_ _Pre_ _Post_ _Null_ _Notnull_ _Maybenull_ _Valid_ _Notvalid_ _Maybevalid_ _Readable_bytes_ _Readable_elements_ _Writable_bytes_ _Writable_elements_ _Null_terminated_ _Pre_readable_size_ _Pre_writable_size_ _Pre_readable_byte_size_ _Pre_writable_byte_size_ _Post_readable_size_ _Post_writable_size_ _Post_readable_byte_size_ _Post_writable_byte_size_

syn keyword   _Ms_annotation_ _Struct_size_bytes_ _Field_size_ _Field_size_opt_ _Field_size_part_ _Field_size_part_opt_ _Field_size_full_ _Field_size_full_opt_ _Field_size_bytes_ _Field_size_bytes_opt_ _Field_size_bytes_part_ _Field_size_bytes_part_opt_ _Field_size_bytes_full_ _Field_size_bytes_full_opt_ _Field_z_ _Field_range_

syn keyword   A_Annotation A_Curr A_Old A_In A_In_opt A_In_z A_In_opt_z A_Inout A_Inout_opt A_Inout_z A_Inout_opt_z A_Out A_Out_opt A_Outptr A_Outptr_opt A_Outptr_result_maybenull A_Outptr_opt_result_maybenull A_Outptr_result_z A_Outptr_opt_result_z A_Outptr_result_maybenull_z A_Outptr_opt_result_maybenull_z A_In_reads A_In_reads_opt A_In_reads_bytes A_In_reads_bytes_opt A_In_reads_to_ptr A_In_reads_to_ptr_opt A_Inout_updates A_Inout_updates_opt A_Inout_updates_bytes A_Inout_updates_bytes_opt A_Inout_updates_to A_Inout_updates_to_opt A_Inout_updates_all A_Inout_updates_all_opt A_Inout_updates_bytes_to A_Inout_updates_bytes_to_opt A_Inout_updates_bytes_all A_Inout_updates_bytes_all_opt A_Out_writes A_Out_writes_opt A_Out_writes_bytes A_Out_writes_bytes_opt A_Out_writes_to_ptr A_Out_writes_to_ptr_opt A_Out_writes_to A_Out_writes_to_opt A_Out_writes_all A_Out_writes_all_opt A_Out_writes_bytes_to A_Out_writes_bytes_to_opt A_Out_writes_bytes_all A_Out_writes_bytes_all_opt A_Ret_null A_Ret_writes A_Ret_writes_z A_Ret_writes_bytes A_Ret_writes_maybenull A_Ret_writes_maybenull_z A_Ret_writes_bytes_maybenull A_Ret_writes_to A_Ret_writes_bytes_to A_Ret_writes_to_maybenull A_Ret_writes_bytes_to_maybenull

syn keyword   A_Annotation A_Ret_restrict A_Ret_never_null A_Ret_null A_Ret_notnull A_Ret_maybenull A_Ret_z A_Ret_maybenull_z A_Ret_valid A_Ret_opt_valid A_Must_inspect_result A_In_range A_Out_range A_Ret_range A_Deref_in_range A_Deref_out_range A_Deref_ret_range A_Pre_equal_to A_Post_equal_to A_Pre_satisfies A_Post_satisfies A_Success A_Return_type_success A_Result_nullonfailure A_Result_zeroonfailure A_Outptr_result_nullonfailure A_Outptr_opt_result_nullonfailure A_Printf_format_string A_Group A_On_failure A_Always A_At A_When A_Post_z A_Post_ptr_invalid A_Post_valid A_Post_invalid A_Post_null A_Post_notnull A_Post_maybenull A_Pre_valid A_Pre_opt_valid A_Pre_invalid A_Pre_unknown A_Pre_notnull A_Pre_maybenull A_Pre_null A_Use_decl_annotations A_Check_return A_Pre A_Post A_Null A_Notnull A_Maybenull A_Valid A_Notvalid A_Maybevalid A_Readable_bytes A_Readable_elements A_Writable_bytes A_Writable_elements A_Null_terminated A_Pre_readable_size A_Pre_writable_size A_Pre_readable_byte_size A_Pre_writable_byte_size A_Post_readable_size A_Post_writable_size A_Post_readable_byte_size A_Post_writable_byte_size

syn keyword   A_Annotation A_Struct_size_bytes A_Field_size A_Field_size_opt A_Field_size_part A_Field_size_part_opt A_Field_size_full A_Field_size_full_opt A_Field_size_bytes A_Field_size_bytes_opt A_Field_size_bytes_part A_Field_size_bytes_part_opt A_Field_size_bytes_full A_Field_size_bytes_full_opt A_Field_z A_Field_range A_Noreturn_function A_Const_function A_Pure_function A_Force_inline_function A_Non_inline_function A_Non_const_function A_Non_pure_function A_Restrict A_Nonnull_all_args A_Nonnull_arg A_Printf_format_at

syn keyword   A_Annotation A_Ret_null_t A_Ret_notnull_t A_Ret_maybenull_t A_Ret_z_t A_Ret_maybenull_z_t A_Ret_valid_t A_Ret_opt_valid_t A_Ret_writes_t A_Ret_writes_z_t A_Ret_writes_bytes_t A_Ret_writes_maybenull_t A_Ret_writes_maybenull_z_t A_Ret_writes_bytes_maybenull_t A_Ret_writes_to_t A_Ret_writes_bytes_to_t A_Ret_writes_to_maybenull_t A_Ret_writes_bytes_to_maybenull_t

syn keyword   CMN_Types   _err_t ERRCODE TO_ERR ERROK ERRFAIL ERRMSG BOOLRET NONZERO NONZEROSZ CREATED DELETED DESTROYED INITIALIZED _bool_t TO_BOOL _TRUE _FALSE CONTAINER_OF RAW_CONTAINER_OF OPT_CONTAINER_OF ASSUME DEBUG_CHECK EMBED_ASSERT STATIC_ASSERT _STATIC_ASSERT TYPEDEF_ASSERT CONST_STR_LEN TO_STR AND_FAKE_INITIALIZER EQ_FAKE_INITIALIZER CONST_CAST CAST_CONSTANT CAST MAX_OF MIN_OF COUNT_OF
