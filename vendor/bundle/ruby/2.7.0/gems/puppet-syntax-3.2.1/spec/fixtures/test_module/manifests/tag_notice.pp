class tag_parameter_test ($tag=undef){
  notify { 'tag_should pass':
    message => 'with flying colours',
  }
}
