version 1.0

workflow fetchngs {
	input{
		File samplesheet
		String input_type = "sra"
		String? ena_metadata_fields
		String sample_mapping_fields = "experiment_accession,run_accession,sample_accession,experiment_alias,run_alias,sample_alias,experiment_title,sample_title,sample_description,description"
		String? nf_core_pipeline
		Boolean? force_sratools_download
		Boolean? skip_fastq_download
		String outdir = "./results"
		String? email
		String? synapse_config
		String custom_config_version = "master"
		String custom_config_base = "https://raw.githubusercontent.com/nf-core/configs/master"
		String? config_profile_name
		String? config_profile_description
		String? config_profile_contact
		String? config_profile_url
		Int max_cpus = 16
		String max_memory = "128.GB"
		String max_time = "240.h"
		Boolean? help
		String? email_on_fail
		Boolean? plaintext_email
		Boolean? monochrome_logs
		String tracedir = "./results/pipeline_info"
		Boolean validate_params = true
		Boolean? show_hidden_params
		Boolean? enable_conda

	}

	call make_uuid as mkuuid {}
	call touch_uuid as thuuid {
		input:
			outputbucket = mkuuid.uuid
	}
	call run_nfcoretask as nfcoretask {
		input:
			samplesheet = samplesheet,
			input_type = input_type,
			ena_metadata_fields = ena_metadata_fields,
			sample_mapping_fields = sample_mapping_fields,
			nf_core_pipeline = nf_core_pipeline,
			force_sratools_download = force_sratools_download,
			skip_fastq_download = skip_fastq_download,
			outdir = outdir,
			email = email,
			synapse_config = synapse_config,
			custom_config_version = custom_config_version,
			custom_config_base = custom_config_base,
			config_profile_name = config_profile_name,
			config_profile_description = config_profile_description,
			config_profile_contact = config_profile_contact,
			config_profile_url = config_profile_url,
			max_cpus = max_cpus,
			max_memory = max_memory,
			max_time = max_time,
			help = help,
			email_on_fail = email_on_fail,
			plaintext_email = plaintext_email,
			monochrome_logs = monochrome_logs,
			tracedir = tracedir,
			validate_params = validate_params,
			show_hidden_params = show_hidden_params,
			enable_conda = enable_conda,
			outputbucket = thuuid.touchedbucket
            }
		output {
			Array[File] results = nfcoretask.results
		}
	}
task make_uuid {
	meta {
		volatile: true
}

command <<<
        python <<CODE
        import uuid
        print("gs://truwl-internal-inputs/nf-fetchngs/{}".format(str(uuid.uuid4())))
        CODE
>>>

  output {
    String uuid = read_string(stdout())
  }
  
  runtime {
    docker: "python:3.8.12-buster"
  }
}

task touch_uuid {
    input {
        String outputbucket
    }

    command <<<
        echo "sentinel" > sentinelfile
        gsutil cp sentinelfile ~{outputbucket}/sentinelfile
    >>>

    output {
        String touchedbucket = outputbucket
    }

    runtime {
        docker: "google/cloud-sdk:latest"
    }
}

task fetch_results {
    input {
        String outputbucket
        File execution_trace
    }
    command <<<
        cat ~{execution_trace}
        echo ~{outputbucket}
        mkdir -p ./resultsdir
        gsutil cp -R ~{outputbucket} ./resultsdir
    >>>
    output {
        Array[File] results = glob("resultsdir/*")
    }
    runtime {
        docker: "google/cloud-sdk:latest"
    }
}

task run_nfcoretask {
    input {
        String outputbucket
		File samplesheet
		String input_type = "sra"
		String? ena_metadata_fields
		String sample_mapping_fields = "experiment_accession,run_accession,sample_accession,experiment_alias,run_alias,sample_alias,experiment_title,sample_title,sample_description,description"
		String? nf_core_pipeline
		Boolean? force_sratools_download
		Boolean? skip_fastq_download
		String outdir = "./results"
		String? email
		String? synapse_config
		String custom_config_version = "master"
		String custom_config_base = "https://raw.githubusercontent.com/nf-core/configs/master"
		String? config_profile_name
		String? config_profile_description
		String? config_profile_contact
		String? config_profile_url
		Int max_cpus = 16
		String max_memory = "128.GB"
		String max_time = "240.h"
		Boolean? help
		String? email_on_fail
		Boolean? plaintext_email
		Boolean? monochrome_logs
		String tracedir = "./results/pipeline_info"
		Boolean validate_params = true
		Boolean? show_hidden_params
		Boolean? enable_conda

	}
	command <<<
		export NXF_VER=21.10.5
		export NXF_MODE=google
		echo ~{outputbucket}
		/nextflow -c /truwl.nf.config run /fetchngs-1.5  -profile truwl  --input ~{samplesheet} 	~{"--samplesheet " + samplesheet}	~{"--input_type " + input_type}	~{"--ena_metadata_fields " + ena_metadata_fields}	~{"--sample_mapping_fields " + sample_mapping_fields}	~{"--nf_core_pipeline " + nf_core_pipeline}	~{true="--force_sratools_download  " false="" force_sratools_download}	~{true="--skip_fastq_download  " false="" skip_fastq_download}	~{"--outdir " + outdir}	~{"--email " + email}	~{"--synapse_config " + synapse_config}	~{"--custom_config_version " + custom_config_version}	~{"--custom_config_base " + custom_config_base}	~{"--config_profile_name " + config_profile_name}	~{"--config_profile_description " + config_profile_description}	~{"--config_profile_contact " + config_profile_contact}	~{"--config_profile_url " + config_profile_url}	~{"--max_cpus " + max_cpus}	~{"--max_memory " + max_memory}	~{"--max_time " + max_time}	~{true="--help  " false="" help}	~{"--email_on_fail " + email_on_fail}	~{true="--plaintext_email  " false="" plaintext_email}	~{true="--monochrome_logs  " false="" monochrome_logs}	~{"--tracedir " + tracedir}	~{true="--validate_params  " false="" validate_params}	~{true="--show_hidden_params  " false="" show_hidden_params}	~{true="--enable_conda  " false="" enable_conda}	-w ~{outputbucket}
	>>>
        
    output {
        File execution_trace = "pipeline_execution_trace.txt"
        Array[File] results = glob("results/*/*html")
    }
    runtime {
        docker: "truwl/nfcore-fetchngs:1.5_0.1.0"
        memory: "2 GB"
        cpu: 1
    }
}
    