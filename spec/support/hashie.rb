# frozen_string_literal: true

# Supress this warning:
#
# `You are setting a key that conflicts with a built-in method Hashie::Mash#size defined in Hash.``
Hashie.logger.level = Logger.const_get 'ERROR'
