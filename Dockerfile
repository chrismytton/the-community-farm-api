FROM ruby:2.1.5-onbuild
CMD ["bundle", "exec", "puma"]
