#!/usr/bin/env ruby

require "fileutils"

module Hotdog
  module Commands
    class Tag < BaseCommand
      def define_options(optparse, options={})
        default_option(options, :retry, 5)
        default_option(options, :tag_source, "user")
        default_option(options, :tags, [])
        optparse.on("--retry NUM") do |v|
          options[:retry] = v.to_i
        end
        optparse.on("--retry-delay SECONDS") do |v|
          options[:retry_delay] = v.to_i
        end
        optparse.on("--source SOURCE") do |v|
          options[:tag_source] = v
        end
        optparse.on("-a TAG", "-t TAG", "--tag TAG", "Use specified tag name/value") do |v|
          options[:tags] << v
        end
      end

      def run(args=[], options={})
        hosts = args.map { |arg|
          arg.sub(/\Ahost:/, "")
        }
        if open_db
          with_retry do
            @db.transaction do
              create_tags(@db, options[:tags])
              options[:tags].each do |tag|
                associae_tag_hosts(@db, tag, hosts)
              end
            end
          end
        end
        hosts.each do |host|
          if options[:tags].empty?
            # nop
          else
            # add all as user tags
            with_retry(options) do
              add_tags(host, options[:tags], source=options[:tag_source])
            end
          end
        end
      end

      private
      def add_tags(host_name, tags, options={})
        code, resp = dog.add_tags(host_name, tags, options)
        if code.to_i / 100 != 2
          raise("dog.add_tags(#{host_name.inspect}, #{tags.inspect}, #{options.inspect}) returns [#{code.inspect}, #{resp.inspect}]")
        end
        resp
      end
    end
  end
end

# vim:set ft=ruby :
