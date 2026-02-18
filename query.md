DATA : lv_string TYPE string VALUE '{"name": "Amar","age":18,"city": "Mumbai"}'.  
DATA(lo_reader) = cl_sxml_string_reader=>create( cl_abap_codepage=>convert_to( lv_json ) ).
TRY.
    lo_reader->next_node( ).
    lo_reader->skip_node( ).
    cl_demo_output=>display( 'JSON is valid' ).
  CATCH cx_sxml_parse_error INTO DATA(lx_parse_error).
    cl_demo_output=>display( lx_parse_error->get_text( ) ).
ENDTRY.