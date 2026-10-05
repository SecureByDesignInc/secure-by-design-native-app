// Generated from the published Secure By Design training catalog.
// Run: node tool/import_site_training.mjs /path/to/site
import 'models.dart';

const publishedPaths = <LearningPath>[
  LearningPath(
      id: "dc01-dc02",
      title: "Build the identity foundation",
      subtitle: "DC01 + DC02 / Active Directory & DNS",
      category: "Network build",
      description:
          "Configure Active Directory and DNS on Windows Server 2025, understand why two controllers matter, and keep a record of the build.",
      icon: "directory",
      published: true,
      studyTime: "5 guided chapters",
      topics: 5,
      materials: [
        LearningResource(
            id: "dc-guide",
            title: "Interactive build guide",
            publisher: "Secure By Design",
            description: "Explore the build and keep your evidence record.",
            url: "https://securebydesigninc.com/training/dc01-dc02/index.html",
            category: "Training materials",
            icon: "directory"),
        LearningResource(
            id: "dc-pdf",
            title: "Companion workbook · PDF",
            publisher: "Secure By Design",
            description: "12 pages · edition 0.3",
            url:
                "https://securebydesigninc.com/training/dc01-dc02/SecureByDesign-DC01-DC02-Workbook.pdf",
            category: "Training materials",
            icon: "directory"),
        LearningResource(
            id: "dc-word",
            title: "Editable workbook · Word",
            publisher: "Secure By Design",
            description: "Make the workbook your own.",
            url:
                "https://securebydesigninc.com/training/dc01-dc02/SecureByDesign-DC01-DC02-Workbook.docx",
            category: "Training materials",
            icon: "directory"),
        LearningResource(
            id: "dc-package",
            title: "Complete learning package · ZIP",
            publisher: "Secure By Design",
            description: "Guide, workbooks, and verification commands.",
            url:
                "https://securebydesigninc.com/training/dc01-dc02/SecureByDesign-DC01-DC02-Learning-Package.zip",
            category: "Training materials",
            icon: "directory")
      ],
      lessons: [
        Lesson(
            id: "training:dc01-dc02:prepare",
            title: "Give every system a purpose",
            minutes: 10,
            summary:
                "Record the starting configuration and explain what the two controllers will do.",
            sections: [
              LessonSection("Understand the why",
                  "Start by understanding the services you are about to build. Then record the names, addresses, and dependencies for two controllers in the same domain."),
              LessonSection("What is Active Directory?",
                  "The shared directory behind domain identities."),
              LessonSection("A directory for people and computers",
                  "Active Directory Domain Services (AD DS) is the Windows Server directory service. It stores objects such as user accounts, computer accounts, and groups, together with their attributes. Administrators use this shared directory to organize identities and manage access consistently."),
              LessonSection("The domain and the controller",
                  "A domain is a logical collection of directory objects, named here sbd.test. A domain controller (DC) is a server running AD DS that stores and serves that directory. DC01 and DC02 are two servers serving the same domain. A forest contains one or more domains; this build starts with one."),
              LessonSection("Identity, permissions, and policy",
                  "Authentication checks who is signing in. Authorization determines what that identity may access. Signing in successfully does not grant access to every resource: the destination service still applies its permissions. Groups make it practical to assign access to roles instead of managing every person separately."),
              LessonSection("Organization and consistent settings",
                  "Organizational units (OUs) organize objects and support delegated administration and Group Policy. Group Policy applies centrally managed settings to users and computers. A global catalog helps find directory objects across a forest; both controllers in this episode provide that role."),
              LessonSection("Remember",
                  "AD DS provides directory and identity services. DNS helps clients find those services. Each has a distinct job."),
              LessonSection("What is DNS?",
                  "The name and service directory that makes AD discoverable."),
              LessonSection("Names become reachable addresses",
                  "Domain Name System (DNS) answers queries about names. An A record maps a hostname to an IPv4 address; an AAAA record maps it to an IPv6 address. In this sample, SBD-DC01.sbd.test resolves to 10.0.10.10. DNS also works on an isolated network without internet access."),
              LessonSection("AD needs service discovery",
                  "Service (SRV) records advertise which servers provide a service. A client uses DNS to discover suitable domain controllers, resolves their hostnames, and contacts a controller for authentication. DNS does not validate the password. A running DC can still be difficult to find if the DNS records or client settings are wrong."),
              LessonSection("What a zone contains",
                  "A DNS zone holds records for a portion of the namespace. With an AD-integrated zone, records are stored in AD DS and replicated to DNS servers within the configured replication scope. Secure dynamic updates restrict which identities may change records. Check the zone scope and update policy on the completed build."),
              LessonSection("Two roles, two kinds of checks",
                  "Installing DNS and installing AD DS provide different services, even when they run on the same server. Query each DNS server for SRV and host records, then check directory replication separately. A correct DNS answer proves neither a successful sign-in nor access to a protected resource."),
              LessonSection("Remember",
                  "Discovery sequence: ask DNS for a domain service → resolve the server name → contact a reachable DC → authenticate."),
              LessonSection("Prepare two separate VMs",
                  "Use new, patched Windows Server 2025 Desktop Experience installations with console access and the required administrative credentials. Keep the virtual network isolated. Obtain approved media and updates through your established offline process."),
              LessonSection("Record names and addresses",
                  "Rename the servers SBD-DC01 and SBD-DC02 and restart as needed. Use 10.0.10.10/24 and 10.0.10.11/24 for this sample. No gateway is needed for this same-subnet exercise; the wider network requires its own approved routing plan."),
              LessonSection("Set the DNS starting point",
                  "For the first DC that will host DNS, use its own static address, 10.0.10.10. Point DC02 at DC01 before promotion. Verify clocks are aligned and document the intended internal time source. Do not add an internet resolver or external forwarder to this isolated network."),
              LessonSection("Inspect each server before promotion",
                  "hostname\nGet-NetIPConfiguration\nGet-DnsClientServerAddress -AddressFamily IPv4\nw32tm /query /status"),
              LessonSection("What to look for",
                  "The two names and static addresses match your plan. DC02 points to 10.0.10.10 for DNS. Record actual time-source output; a configured address alone does not prove time synchronization."),
              LessonSection("Avoid this mistake",
                  "A DNS server address configured on a network adapter does not install DNS. DC01 will not answer DNS queries until its DNS service is installed and running."),
              LessonSection("Keep your evidence",
                  "Record your VM names, OS builds, addresses, DNS settings, and any differences from the sample.")
            ],
            question:
                "Before promoting DC02, where should it look for the existing domain's DNS?",
            answers: [
              "DC01, once its domain DNS is available",
              "A public DNS resolver",
              "Only itself, before DNS is installed"
            ],
            correctAnswer: 0,
            explanation:
                "DC02 needs to locate the existing directory through DNS. In this sample, DC01 provides that service first.",
            sourceUrl:
                "https://securebydesigninc.com/training/dc01-dc02/index.html#prepare",
            sourceLabel: 'Open the complete guide'),
        Lesson(
            id: "training:dc01-dc02:dc01",
            title: "Create the first domain controller",
            minutes: 10,
            summary:
                "Create the sample forest and bring AD DS and DNS online on DC01.",
            sections: [
              LessonSection("Understand the why",
                  "A new forest establishes the directory's initial boundary. Here, sbd.test is a sample domain, not an existing company domain. Follow this path only for a new forest."),
              LessonSection("Add the server role",
                  "On DC01, open Server Manager → Manage → Add Roles and Features. Choose the local server and Active Directory Domain Services, including its management tools."),
              LessonSection("Create the forest",
                  "Select Promote this server to a domain controller, then Add a new forest. Enter sbd.test. For this all-2025 sample, select Windows Server 2025 functional levels. Include DNS and the global catalog. Enter and confirm a unique Directory Services Restore Mode password on the server."),
              LessonSection("Review and promote",
                  "Review DNS options, the SBD NetBIOS name, paths, and prerequisite results. A parent-zone delegation is not required for this isolated .test forest. Resolve blocking errors, install, and allow the restart. Then inspect the services and domain."),
              LessonSection("Verify DC01 after the restart",
                  "Get-ADDomain | Select-Object DNSRoot, NetBIOSName\nGet-Service NTDS,DNS,Netlogon\nGet-SmbShare -Name SYSVOL,NETLOGON"),
              LessonSection("What to look for",
                  "The domain is sbd.test with NetBIOS name SBD. NTDS, DNS, and Netlogon are running, and SYSVOL and NETLOGON shares exist. Investigate missing services or shares before moving on."),
              LessonSection("Avoid this mistake",
                  "Installing the AD DS role is only the first part. The promotion wizard creates the domain controller; a completed role installation alone is not a completed forest."),
              LessonSection("Keep your evidence",
                  "Record the domain, promotion outcome, service checks, and the file names of your screenshots or saved output. Do not enter passwords.")
            ],
            question:
                "What turns an AD DS role installation into a domain controller?",
            answers: [
              "Renaming the server",
              "Completing domain-controller promotion",
              "Adding a second network adapter"
            ],
            correctAnswer: 1,
            explanation:
                "Promotion configures the directory role for a new forest or an existing domain. Merely adding the role is insufficient.",
            sourceUrl:
                "https://securebydesigninc.com/training/dc01-dc02/index.html#dc01",
            sourceLabel: 'Open the complete guide'),
        Lesson(
            id: "training:dc01-dc02:dc02",
            title: "Give the domain a second service point",
            minutes: 10,
            summary:
                "Promote DC02 into the existing domain and inspect the replication relationship.",
            sections: [
              LessonSection("Understand the why",
                  "A second domain controller gives the domain another live service point. Read why this is a standard availability practice, then add DC02 and verify the result."),
              LessonSection("Why use two domain controllers?",
                  "Keep identity and DNS services available when one server is unavailable."),
              LessonSection("Remove the single-server dependency",
                  "With one DC, its outage removes the only live directory service point. With two healthy, reachable controllers, clients can discover a surviving DC for supported operations. This also lets you patch or restart one server while the other continues serving requests. Reconnection may take time; uninterrupted service is not guaranteed."),
              LessonSection("Both controllers do useful work",
                  "Both writable DCs can process normal directory changes and authentication requests. Replication shares directory changes between them. They are not a primary server and an idle spare. Certain operations still depend on a single FSMO role holder, so role placement and recovery need their own plan."),
              LessonSection("Make the redundancy real",
                  "Microsoft recommends at least two virtualized DCs per domain on different virtualization hosts. Two VMs on one host share that host as a failure point. Consider shared storage, power, and network dependencies too. Run DNS on both here, verify zone replication, and configure clients to use both internal DNS addresses."),
              LessonSection("Availability still needs recovery",
                  "Replication can spread an accidental deletion or harmful change to both servers. Keep protected backups and test recovery separately. Two is a starting point for this design, not a universal capacity target: additional sites, users, and recovery needs may require more controllers."),
              LessonSection("Remember",
                  "Before relying on DC02, verify replication and DNS, review shared dependencies, and test client discovery during an approved maintenance window."),
              LessonSection("Reach the existing directory",
                  "On DC02, confirm DNS points to 10.0.10.10. Query the domain service records and resolve SBD-DC01.sbd.test. Check network reachability and clock alignment before promotion."),
              LessonSection("Add a controller to this domain",
                  "Install the AD DS role and management tools. In the promotion wizard choose Add a domain controller to an existing domain, enter sbd.test, and authenticate with an authorized Domain Admin account. Select DNS and global catalog, leave Read only domain controller unselected, and set the DSRM password securely."),
              LessonSection("Finish and inspect",
                  "Review site placement, replication source, and prerequisite results; install and restart. Keep DC02 using DC01 for DNS until initial inbound replication is healthy. Then document the final internal resolver order for both DCs, retaining a reachable partner and self as appropriate to the design."),
              LessonSection("Inspect both controllers and replication",
                  "Get-ADDomainController -Filter * |\n  Select-Object HostName, IPv4Address, IsGlobalCatalog\nrepadmin /replsummary\nrepadmin /showrepl SBD-DC02"),
              LessonSection("What to look for",
                  "Both hostnames appear with the intended addresses and global catalog roles. After initial convergence, replication checks show successful recent attempts and no unresolved replication failures. Inspect errors rather than assuming the restart completed replication."),
              LessonSection("Avoid this mistake",
                  "Choosing Add a new forest creates a different directory. For this chapter, DC02 joins the domain established by DC01."),
              LessonSection("Keep your evidence",
                  "Record both controllers, replication status and collection time, plus any failures or follow-up actions.")
            ],
            question:
                "A damaging directory change reaches both controllers. What does that illustrate?",
            answers: [
              "DC02 should never replicate",
              "Two controllers guarantee recovery",
              "Replication and historical recovery are different capabilities"
            ],
            correctAnswer: 2,
            explanation:
                "Both controllers can hold the same unwanted change. Recovery requires protected backups and an appropriate, tested recovery procedure.",
            sourceUrl:
                "https://securebydesigninc.com/training/dc01-dc02/index.html#dc02",
            sourceLabel: 'Open the complete guide'),
        Lesson(
            id: "training:dc01-dc02:verify",
            title: "Ask the services to prove they work",
            minutes: 10,
            summary:
                "Query each DNS service explicitly and inspect domain-controller health.",
            sections: [
              LessonSection("Understand the why",
                  "A service can be running while its configuration is wrong. Query each DNS server by address so the result tells you which server answered. Capture actual results and failures in your evidence record."),
              LessonSection("Query each DNS service",
                  "Run the checks below in an administrative Windows PowerShell session with the server tools available. Query the domain controller locator SRV records separately on DC01 and DC02. SRV means service record."),
              LessonSection("Check the host records",
                  "Resolve SBD-DC01.sbd.test and SBD-DC02.sbd.test against both DNS servers. Expect 10.0.10.10 and 10.0.10.11 respectively. A locator response does not, by itself, prove that every listed host is reachable."),
              LessonSection("Review health in context",
                  "Run DCDiag and review each result. In an isolated environment, classify any external-resolution failures against the intended design. The workstation in this scene is a test viewpoint; joining and validating a real Windows client is an optional extension after routing and client prerequisites are ready."),
              LessonSection("Read-only DNS and health checks",
                  "\$servers = '10.0.10.10','10.0.10.11'\nforeach (\$server in \$servers) {\n  Write-Output \"DNS server: \$server\"\n  Resolve-DnsName '_ldap._tcp.dc._msdcs.sbd.test' -Type SRV -Server \$server\n  Resolve-DnsName 'SBD-DC01.sbd.test' -Type A -Server \$server\n  Resolve-DnsName 'SBD-DC02.sbd.test' -Type A -Server \$server\n}\ndcdiag /test:DNS /e /v\nrepadmin /replsummary"),
              LessonSection("What to look for",
                  "Each DNS service returns domain locator records for the configured controllers and the correct host addresses. Review DCDiag findings and replication failures individually. Save output with host, time, and interpretation; do not record an automatic pass because the command ran."),
              LessonSection("Avoid this mistake",
                  "A successful ping confirms limited IP reachability, not DNS service discovery, directory replication, or authentication."),
              LessonSection("Keep your evidence",
                  "For each DNS server, record the observed SRV and A-record results, test time, failures, and what the results establish.")
            ],
            question: "What does a successful DNS locator query establish?",
            answers: [
              "The queried server returned the requested service records",
              "Every authentication control is satisfied",
              "The system is authorized to operate"
            ],
            correctAnswer: 0,
            explanation:
                "The query demonstrates a particular DNS response. Reachability, authentication, control effectiveness, and authorization require additional evidence and decisions.",
            sourceUrl:
                "https://securebydesigninc.com/training/dc01-dc02/index.html#verify",
            sourceLabel: 'Open the complete guide'),
        Lesson(
            id: "training:dc01-dc02:evidence",
            title: "Leave a build someone else can understand",
            minutes: 10,
            summary:
                "Assemble your configuration record, test evidence, and remaining work.",
            sections: [
              LessonSection("Understand the why",
                  "The useful deliverable is a build you can explain and check again. Your evidence record connects each action with an observed result and identifies what remains unresolved."),
              LessonSection("Describe the final state",
                  "Record the domain, both controllers, DNS resolver choices, site placement, and actual role holders. Preserve the distinction between the intended design and observed configuration."),
              LessonSection("Keep a small evidence set",
                  "Store your environment outputs locally with descriptive filenames and collection times. In this companion, write a short summary and the file references; the form does not upload or collect your screenshots, server output, or credentials."),
              LessonSection("Plan the next check",
                  "List remaining hardening, auditing, backup, recovery, and client-validation work. Assign an owner or next action. Revisit checks after relevant configuration changes. Export the evidence record before moving devices."),
              LessonSection("Record the current role holders",
                  "Get-ADDomain |\n  Select-Object DNSRoot, PDCEmulator, RIDMaster, InfrastructureMaster\nGet-ADForest |\n  Select-Object RootDomain, SchemaMaster, DomainNamingMaster"),
              LessonSection("What to look for",
                  "The record identifies the actual role holders and links configuration decisions to dated test results. Open issues remain visible. Lesson completion records learning activity; it is not a system authorization decision."),
              LessonSection("Avoid this mistake",
                  "A diagram becoming complete does not establish that your VM passed a check. The model tells the lesson story; your observations establish what happened in your environment."),
              LessonSection("Keep your evidence",
                  "Summarize the final state, reference your evidence files, and list remaining work with a next action or review trigger.")
            ],
            question: "Which event is a useful reason to revisit the evidence?",
            answers: [
              "Only the anniversary of the video",
              "A relevant configuration change or new finding",
              "Finishing the animation"
            ],
            correctAnswer: 1,
            explanation:
                "Changes and findings can affect prior conclusions. A monitoring plan defines when and how to reassess the relevant security state.",
            sourceUrl:
                "https://securebydesigninc.com/training/dc01-dc02/index.html#evidence",
            sourceLabel: 'Open the complete guide')
      ]),
  LearningPath(
      id: "rmf-boe-ato",
      title:
          "Risk Management Framework, Body of Evidence & Authorization to Operate",
      subtitle:
          "Prepare the network you build in the previous training for authorization.",
      category: "Network authorization",
      description:
          "The previous training grows with the steps used to build Inside the Network. This course follows that same system through the Risk Management Framework (RMF), develops its Body of Evidence, and prepares an Authorization to Operate (ATO) package for review.",
      icon: "risk",
      published: true,
      studyTime: "12 modules · 36 topics · 24 study hours",
      topics: 36,
      materials: [
        LearningResource(
            id: "rmf-guide",
            title: "Interactive authorization course",
            publisher: "Secure By Design",
            description: "Lessons, evidence examples, and the capstone.",
            url: "https://securebydesigninc.com/training/rmf/index.html",
            category: "Training materials",
            icon: "directory"),
        LearningResource(
            id: "rmf-word",
            title: "Full training catalog · Word",
            publisher: "Secure By Design",
            description: "Edition 1.0 · 12 modules",
            url:
                "https://securebydesigninc.com/training/rmf/Secure_By_Design_RMF_Training_Catalog.docx",
            category: "Training materials",
            icon: "directory"),
        LearningResource(
            id: "rmf-evidence",
            title: "Body of Evidence examples and starters",
            publisher: "Secure By Design",
            description:
                "Ten examples with editable Markdown and CSV starters.",
            url:
                "https://securebydesigninc.com/training/rmf/index.html#evidence",
            category: "Training materials",
            icon: "directory"),
        LearningResource(
            id: "rmf-capstone",
            title: "Authorization package capstone",
            publisher: "Secure By Design",
            description: "Assemble, defend, and maintain the practice package.",
            url:
                "https://securebydesigninc.com/training/rmf/index.html#capstone",
            category: "Training materials",
            icon: "directory")
      ],
      lessons: [
        Lesson(
            id: "training:rmf-boe-ato:01",
            title: "01 · RMF and authorization fundamentals",
            minutes: 60,
            summary:
                "Explain the relationship between the RMF lifecycle, the Body of Evidence, the authorization package, and the authorization decision.",
            sections: [
              LessonSection("Start with the mission, then ask about risk.",
                  "The Risk Management Framework (RMF) connects a system’s purpose to the safeguards, evidence, and decisions needed to operate it. Begin with what the organization needs the system to do. Then consider what could happen if information is exposed, changed incorrectly, or unavailable.\n\nAn Authorization to Operate (ATO) records a management decision about risk. Installing security tools or finishing a checklist does not make that decision. The authorization package gives the responsible official information to evaluate it."),
              LessonSection(
                  "Everyone contributes. The responsibilities differ.",
                  "The system owner is accountable for the system and its package. An Information System Security Manager (ISSM) oversees the security program; an Information System Security Officer (ISSO) supports day-to-day implementation and documentation. Engineers operate safeguards and produce records.\n\nA control assessor evaluates the evidence against the assessment objectives. Common control providers document inherited protections. The Authorizing Official (AO) makes the authorization and risk-acceptance decision within their authority. Local appointments determine the precise division of work."),
              LessonSection("Follow the claim all the way to the decision.",
                  "The Body of Evidence contains the records supporting how the system is secured and operated. The authorization package brings the decision-relevant material together: the plans, assessment reports, outstanding actions, executive summary, and supporting references required by the authority.\n\nA reviewer should be able to move from a requirement to its implementation, to evidence, to an assessment result, and finally to the effect on risk. Missing links are questions to resolve, not paperwork to hide."),
              LessonSection("From a claim to a decision",
                  "Claim: “Privileged account changes are logged and reviewed.”\n\nEvidence: The selected-event configuration, a sample event, and the analyst’s review record.\n\nAssessment: The assessor tests the event and checks whether the expected review occurred.\n\nDecision: The AO considers the supported result and any remaining gap in the system’s risk context."),
              LessonSection("Build",
                  "Create a role map for the system owner, ISSM, ISSO, engineers, control assessor, common control provider, and Authorizing Official (AO). Identify applicable privacy responsibilities."),
              LessonSection("Prove",
                  "Given a missing test result and an unresolved risk, identify who supplies evidence, who assesses it, and who has authority to accept the risk.")
            ],
            question:
                "The team installed a SIEM and completed its checklist. What comes next?",
            answers: [
              "Treat the system as authorized.",
              "Support implementation claims with assessment evidence and the required risk review.",
              "Replace the SSP with screenshots of the SIEM."
            ],
            correctAnswer: 1,
            explanation:
                "Security tools support control implementation. The assessor evaluates the evidence, and the AO makes the authorization decision.",
            sourceUrl:
                "https://securebydesigninc.com/training/rmf/index.html#catalog/01",
            sourceLabel: 'Open the complete guide'),
        Lesson(
            id: "training:rmf-boe-ato:02",
            title: "02 · Prepare and define the system",
            minutes: 90,
            summary:
                "Establish what is being authorized, why it exists, and which organizational and system preparation decisions must be made before documentation expands.",
            sections: [
              LessonSection("Describe the work the system supports.",
                  "Identify the mission, stakeholders, information owners, and dependencies before choosing documents. Record who needs the system, what work it enables, and what service interruption or misuse would affect.\n\nPreparation also happens at the organizational level: risk tolerance, common controls, resources, roles, and oversight influence each system’s approach. Prepare is explicit in NIST SP 800-37 Revision 2."),
              LessonSection("Draw the boundary, then test the assumptions.",
                  "An authorization boundary identifies the system being evaluated. It is more than a subnet diagram. Consider management interfaces, hosting infrastructure, shared services, information flows, and dependencies.\n\nA component outside the boundary can still affect risk. Document its relationship and the responsible party. Do not use a boundary choice to make a difficult dependency disappear."),
              LessonSection("Identify the governing direction.",
                  "Record the authority, relevant policies, adopted control versions, required reviewers, and expected deliverables. Clarify which protections are system-specific, inherited, or shared.\n\nAn inherited-control claim needs an identified provider and applicable evidence. In the separate isolated lab exercise, transfers across the air gap remain manual and human-controlled."),
              LessonSection("Resolve a shared-service question",
                  "Question: Is the virtualization host covered by this package?\n\nRecord: Identify the host, its administrator, and the systems it supports.\n\nResolve: Document whether it is inside the boundary or provided through a documented external/common service.\n\nProve: Keep the architecture, inventory, and responsibility record consistent."),
              LessonSection("Build",
                  "Draft a mission statement, boundary diagram, asset list, data flow narrative, stakeholder register, and assumptions log. Record the governing authority, approved standards, overlays, and review expectations."),
              LessonSection("Prove",
                  "Explain whether a shared service, hypervisor, management path, or offline update transfer is inside the boundary, external, or inherited, and identify supporting responsibility evidence.")
            ],
            question:
                "A service sits outside the boundary but provides identity for the system. What should the package do?",
            answers: [
              "Ignore it because it is external.",
              "Assume all of its controls are inherited.",
              "Document the dependency, responsibilities, and applicable assurance evidence."
            ],
            correctAnswer: 2,
            explanation:
                "Being outside a boundary does not remove a dependency or establish inheritance.",
            sourceUrl:
                "https://securebydesigninc.com/training/rmf/index.html#catalog/02",
            sourceLabel: 'Open the complete guide'),
        Lesson(
            id: "training:rmf-boe-ato:03",
            title: "03 · Categorize information and impacts",
            minutes: 90,
            summary:
                "Justify confidentiality, integrity, and availability impacts using information types and mission consequences. Treat privacy applicability as an explicit decision.",
            sections: [
              LessonSection("Evaluate the consequences for each objective.",
                  "Confidentiality concerns inappropriate disclosure. Integrity concerns unauthorized or improper change. Availability concerns reliable access when needed. Categorization starts with information types and the consequences for the mission.\n\nDifferent objectives can have different impacts. Record the reasoning and applicable methodology; an isolated network alone does not decide the result."),
              LessonSection("Write a rationale another person can review.",
                  "Explain the information processed, the people or mission affected, the potential consequences, and the justification for each impact determination. Capture assumptions and the required approval.\n\nIf a system’s mission changes, revisit the rationale. Repeating an inherited label without understanding its basis does not make the categorization defensible."),
              LessonSection("Apply the right categorization authority.",
                  "Federal and national security system contexts do not use identical selection rules. Determine which requirements apply before choosing a baseline or overlay. Consider privacy applicability explicitly.\n\nThe optional Secure By Design exercise uses Moderate confidentiality, Low integrity, and Low availability as its stated planning input. That example must not be imposed on another system or treated as an authorization result."),
              LessonSection("A dependency changes the discussion",
                  "Initial rationale: An internal service is needed for routine business support.\n\nNew information: A mission process now depends on timely access to it.\n\nReview: Reevaluate availability consequences under the applicable categorization method.\n\nUpdate: Record the rationale and route it for the required review."),
              LessonSection("Build",
                  "Prepare a categorization worksheet with information types, impact rationale, mission dependencies, approval routing, and privacy considerations. Document the methodology required by the system’s authority."),
              LessonSection("Prove",
                  "Defend a changed availability impact after a new mission dependency. Explain why an air gap alone does not establish a low impact level or eliminate risk.")
            ],
            question: "Does an air gap determine the system’s impact level?",
            answers: [
              "No. Mission consequences and the applicable categorization method determine the rationale.",
              "Yes. It always makes confidentiality Low.",
              "Yes. It eliminates integrity risk."
            ],
            correctAnswer: 0,
            explanation:
                "Isolation is a design characteristic. It does not replace the mission and information impact analysis.",
            sourceUrl:
                "https://securebydesigninc.com/training/rmf/index.html#catalog/03",
            sourceLabel: 'Open the complete guide'),
        Lesson(
            id: "training:rmf-boe-ato:04",
            title: "04 · Select and tailor controls",
            minutes: 120,
            summary:
                "Translate the approved categorization and applicable requirements into a justified, assignable control set. Distinguish the control catalog from a selected baseline.",
            sections: [
              LessonSection(
                  "A catalog is not the same as a selected control set.",
                  "NIST SP 800-53 describes security and privacy controls. A baseline provides a starting set under an applicable selection method. Overlays and authority-specific requirements can change that starting point.\n\nSP 800-53B provides federal baselines; a national security or SAP selection also requires the applicable CNSS and program direction. Keep these contexts distinct."),
              LessonSection("Make tailoring decisions visible.",
                  "Record why a control is added, adjusted, or considered not applicable and who must approve that decision. Resolve organization-defined parameters such as roles, frequencies, and time periods using the governing direction.\n\nDo not mark a requirement not applicable merely because it is difficult to implement. A reviewer needs both the rationale and its authorized disposition."),
              LessonSection("Allocate work before asking for evidence.",
                  "Identify the owner of each implementation. Distinguish system-specific controls, common controls supplied by a provider, and hybrid controls with shared responsibility.\n\nA Security Control Traceability Matrix (SCTM) can connect the selected requirement, parameter values, ownership, implementation, evidence, assessment result, and associated risk. Its exact format follows local requirements."),
              LessonSection("An inheritance claim needs support",
                  "Claim: “Account management is inherited.”\n\nQuestion: Which provider performs which part of the requirement?\n\nEvidence: Provider documentation, applicable assessment information, and local responsibilities.\n\nRecord: An allocation that separates inherited activities from the system team’s work."),
              LessonSection("Build",
                  "Start a Security Control Traceability Matrix (SCTM). Record control revision, applicability, tailoring rationale, organization-defined parameters, owner, and system-specific, common, or hybrid allocation."),
              LessonSection("Prove",
                  "Resolve a proposed not-applicable control and an inherited-control claim using evidence and the required approval path. Pin the selected control and assessment-procedure versions.")
            ],
            question:
                "A team calls a difficult control not applicable. What is missing?",
            answers: [
              "A tool screenshot.",
              "A justified applicability decision and the required approval.",
              "A shorter control identifier."
            ],
            correctAnswer: 1,
            explanation:
                "Tailoring must follow the governing process and preserve the rationale.",
            sourceUrl:
                "https://securebydesigninc.com/training/rmf/index.html#catalog/04",
            sourceLabel: 'Open the complete guide'),
        Lesson(
            id: "training:rmf-boe-ato:05",
            title: "05 · Write the system security plan",
            minutes: 120,
            summary:
                "Write a System Security Plan (SSP) that describes the actual system and explains how selected controls are implemented.",
            sections: [
              LessonSection("Describe the system that actually exists.",
                  "The System Security Plan (SSP) identifies the system, its environment, responsible parties, dependencies, and how selected controls are implemented. Keep it consistent with the inventory and architecture.\n\nDescribe implemented safeguards and clearly identify planned work. A future improvement should not appear as if it already operates."),
              LessonSection("Make the implementation understandable.",
                  "Explain who performs an activity, what they do, where it applies, when it happens, and which records support the claim. Use the exact selected requirements and parameters as the basis.\n\n“We comply with policy” leaves essential questions unanswered. A useful statement describes the actual process and links to evidence without claiming more than the evidence supports."),
              LessonSection("Connect the supporting plans.",
                  "Configuration, access, incident response, contingency, media, privacy, and other applicable plans describe supporting processes. Connect them to the SSP rather than copying inconsistent versions of the same procedure into several places.\n\nRecord the owner, version, and review status of each reference. A plan is evidence of intended process; records and tests help show that the process is carried out."),
              LessonSection("Improve a vague implementation statement",
                  "Before: “Audit logs are reviewed according to policy.”\n\nBetter: Identify the assigned reviewer, covered event sources, approved review schedule, exception process, and review record.\n\nCheck: Does the scope match the selected requirement and actual source inventory?\n\nLink: Point to the configuration, sample events, and completed review records."),
              LessonSection("Build",
                  "Draft SSP sections for the boundary, system components, roles, and selected controls. Write statements covering who performs the activity, what happens, where it occurs, when it happens, and the supporting evidence."),
              LessonSection("Prove",
                  "Replace a vague “compliant with policy” statement with a specific implementation narrative. Reconcile it with the diagrams, inventory, and inheritance record.")
            ],
            question: "Which SSP statement is most useful?",
            answers: [
              "“The organization is fully compliant.”",
              "“A security product is installed.”",
              "A specific description of the activity, owner, scope, frequency, and evidence."
            ],
            correctAnswer: 2,
            explanation:
                "A defensible implementation statement gives reviewers something concrete to examine, interview about, and test.",
            sourceUrl:
                "https://securebydesigninc.com/training/rmf/index.html#catalog/05",
            sourceLabel: 'Open the complete guide'),
        Lesson(
            id: "training:rmf-boe-ato:06",
            title: "06 · Connect implementation to proof",
            minutes: 120,
            summary:
                "Collect technical and operational evidence that addresses the selected requirement and can support an assessment.",
            sections: [
              LessonSection("Capture the configuration and its context.",
                  "A configuration export or hardening checklist is useful when the reviewer can identify the system, setting, scope, version, and collection time. Retain the review or validation record as appropriate.\n\nA passing automated check has a defined scope. Manual checks, applicability decisions, and technical limitations still need attention."),
              LessonSection(
                  "Operational records show whether a process happens.",
                  "Logs, scan reports, incident tickets, access reviews, and backup test records support different claims. Connect each item to the question it can answer.\n\nThe optional examples use Splunk, Tenable, and Trellix records. Equivalent records can support the exercise. Owning a named product does not itself establish that the selected control is effective."),
              LessonSection("Coverage is part of evidence quality.",
                  "Check whether all relevant systems were included, credentials worked, data was current, and the collection method was appropriate. Preserve collection failures rather than silently excluding them.\n\nExplain what the evidence cannot show. A vulnerability scan does not demonstrate every control, and a backup job success message does not by itself prove recovery."),
              LessonSection("A clean scan with a coverage problem",
                  "Report: The scan reports no critical findings.\n\nInspection: Authenticated checks failed for two in-scope hosts.\n\nConclusion: The report does not support a complete credentialed assessment of those hosts.\n\nFollow-up: Correct access, rerun the intended checks, and retain the original coverage limitation."),
              LessonSection("Build",
                  "Collect configuration exports, a reviewed hardening checklist, scan coverage, log review records, and a recovery-test result. Use Splunk, Tenable, and Trellix examples or equivalent supplied training records."),
              LessonSection("Prove",
                  "Explain what each item proves and leaves untested. Identify a failed authenticated scan, an unreviewed alert, and a configuration screenshot that lacks system or time context.")
            ],
            question:
                "A scan reports no findings, but credentials failed. What can you conclude?",
            answers: [
              "All required checks passed.",
              "The available result is limited; credentialed coverage must be resolved.",
              "No evidence needs to be retained."
            ],
            correctAnswer: 1,
            explanation:
                "The absence of reported findings is not proof that intended checks ran successfully.",
            sourceUrl:
                "https://securebydesigninc.com/training/rmf/index.html#catalog/06",
            sourceLabel: 'Open the complete guide'),
        Lesson(
            id: "training:rmf-boe-ato:07",
            title: "07 · Organize the Body of Evidence",
            minutes: 90,
            summary:
                "Make evidence easy to retrieve, trace, and maintain across system changes and assessment cycles.",
            sections: [
              LessonSection("Give each record a stable identity.",
                  "An evidence index lets a reviewer locate a record without relying on a folder name or someone’s memory. Record its identifier, title, scope, owner, collection date, version, and location.\n\nUse a naming convention that is easy to maintain. Protect and retain evidence according to the applicable requirements."),
              LessonSection("Trace objectives, not just filenames.",
                  "Link evidence to the relevant requirement and assessment objective. Keep the implementation statement and assessment conclusion connected to the same scope.\n\nOne item may support several objectives, and one objective may need several items. Record the limits of each relationship."),
              LessonSection("Keep current and historical evidence distinct.",
                  "When a system changes, identify which claims and records are affected. Keep version history so a reviewer can understand what was assessed at a particular time.\n\nA current filename on an old screenshot does not make the evidence current. Record collection and review dates separately when they mean different things."),
              LessonSection("A broken link in the package",
                  "Index: EV-003 is listed as proof of current privileged event coverage.\n\nRecord: The export predates a new management host.\n\nGap: The record cannot support the updated coverage claim.\n\nAction: Collect the missing evidence and reconcile the SSP, source inventory, and assessment scope."),
              LessonSection("Build",
                  "Create a master evidence index and link each selected control objective to the implementation, supporting record, owner, collection date, system scope, document version, and review status."),
              LessonSection("Prove",
                  "Find stale evidence, a missing record, and a mismatch between the SSP and an exported configuration. Record the gap and its effect on the assessment.")
            ],
            question:
                "A screenshot predates a major configuration change. What is the best next step?",
            answers: [
              "Rename it with today’s date.",
              "Leave it because the control number matches.",
              "Review its applicability and obtain current evidence for the changed scope."
            ],
            correctAnswer: 2,
            explanation:
                "Evidence must be relevant to the implementation and time period being assessed.",
            sourceUrl:
                "https://securebydesigninc.com/training/rmf/index.html#catalog/07",
            sourceLabel: 'Open the complete guide'),
        Lesson(
            id: "training:rmf-boe-ato:08",
            title: "08 · Plan and perform assessment",
            minutes: 120,
            summary:
                "Turn implementation claims into assessable objectives and distinguish a planned test from an observed result.",
            sections: [
              LessonSection("Agree on what will be assessed.",
                  "The assessment plan describes the objectives, scope, methods, objects, responsibilities, schedule, and practical constraints. Address the required assessor independence and approval path.\n\nSelect methods and coverage appropriate to the requirement and risk. Document sampling decisions instead of leaving them implicit."),
              LessonSection("Use examine, interview, and test deliberately.",
                  "Examine records and configurations. Interview people responsible for the process. Test the capability or behavior when appropriate. These methods answer different questions and can complement one another.\n\nCapture the expected result, actual observation, evidence references, and limitations. Follow the adopted SP 800-53A procedures and authority-specific instructions."),
              LessonSection("Report the result the evidence supports.",
                  "The Security Assessment Report (SAR) communicates what was assessed and the resulting findings. Connect each conclusion to the relevant objective, observed result, and supporting evidence.\n\nUnsupported objectives remain unresolved. Document remediation and retests without erasing the original finding or disguising a limitation as a successful result."),
              LessonSection("Test a privileged account-change event",
                  "Plan: Specify the permitted event, relevant sources, expected record, and review process.\n\nObserve: Generate the event in the lab and inspect collection and review records.\n\nEvaluate: Compare observations to each selected objective.\n\nReport: Preserve the result, scope, evidence references, and any coverage gap."),
              LessonSection("Build",
                  "Draft a Security Assessment Plan with objectives, methods, objects, scope, sampling rationale, responsibilities, and schedule. Execute sample procedures and prepare a Security Assessment Report (SAR) excerpt."),
              LessonSection("Prove",
                  "Link each conclusion to the assessment objective, evidence, actual observation, and limitation. Record unsupported objectives rather than treating a lack of evidence as a successful test.")
            ],
            question:
                "A required assessment objective has no supporting evidence. Should it be marked satisfied?",
            answers: [
              "No. Record the gap and resolve it through the assessment process.",
              "Yes, if the owner expects it to work.",
              "Yes, if another control passed."
            ],
            correctAnswer: 0,
            explanation:
                "Assessment conclusions require support for the relevant objective.",
            sourceUrl:
                "https://securebydesigninc.com/training/rmf/index.html#catalog/08",
            sourceLabel: 'Open the complete guide'),
        Lesson(
            id: "training:rmf-boe-ato:09",
            title: "09 · Manage findings and residual risk",
            minutes: 90,
            summary:
                "Translate weaknesses into mission-relevant risk and an accountable response. Explain the difference between technical severity and contextual risk.",
            sections: [
              LessonSection("Translate the weakness into mission risk.",
                  "A finding identifies a weakness or unmet objective. Risk analysis considers the threat, exposure, consequences, existing safeguards, and remaining uncertainty in the system’s context.\n\nTechnical severity helps inform prioritization, but it is not the complete risk determination. Explain the mission impact and the reasoning behind the proposed response."),
              LessonSection("Write an action that can be managed.",
                  "A Plan of Action and Milestones (POA&M) records the weakness, affected scope, responsible owner, planned actions, dates, resources, dependencies, and closure criteria.\n\n“Fix soon” is not a milestone. A useful milestone describes a verifiable action and a target date, with a clearly accountable owner."),
              LessonSection("Verify the correction before closing the record.",
                  "Link the corrective action to the original finding. Retest the relevant condition and retain the result. Track delays and changed assumptions through the required review process.\n\nA POA&M is a management record; it does not itself accept risk or grant permission to operate. Those decisions follow the responsible authority’s process."),
              LessonSection("Make a logging finding actionable",
                  "Weakness: One management host is missing from centralized audit collection.\n\nResponse: Restore approved collection and update source coverage records.\n\nMilestones: Confirm configuration, test the selected event, and verify the assigned review process.\n\nClosure: Retain the successful retest and reconcile the SSP, evidence index, and SAR disposition."),
              LessonSection("Build",
                  "Create a risk analysis record and Plan of Action and Milestones (POA&M) entry with the weakness, affected assets and controls, owner, planned milestones, target dates, resources, status, and closure criteria."),
              LessonSection("Prove",
                  "Prioritize two findings with different exposure and mission impact. Preserve the original result, document remediation, and require verification before claiming closure.")
            ],
            question:
                "Does adding a finding to a POA&M mean its risk has been accepted?",
            answers: [
              "Yes, automatically.",
              "Only if the spreadsheet has a due date.",
              "No. Risk acceptance follows the authorized decision process."
            ],
            correctAnswer: 2,
            explanation:
                "Tracking a weakness and accepting its risk are different actions.",
            sourceUrl:
                "https://securebydesigninc.com/training/rmf/index.html#catalog/09",
            sourceLabel: 'Open the complete guide'),
        Lesson(
            id: "training:rmf-boe-ato:10",
            title: "10 · Assemble the authorization package",
            minutes: 120,
            summary:
                "Build a reviewable package whose claims, assessment results, and open risks agree across documents.",
            sections: [
              LessonSection("Assemble the decision-focused record.",
                  "Bring together the executive summary, security and applicable privacy plans, assessment reports, POA&M, and required supporting material. Use a manifest to identify the exact versions under review.\n\nThe AO determines additional supporting information needed for the decision. Local formats differ, but the package must remain coherent and reviewable."),
              LessonSection("Check the relationships between documents.",
                  "Compare the boundary, inventory, selected controls, implementation statements, findings, and open actions. Resolve inconsistent identifiers, status, dates, and scope.\n\nA package may be complete as a collection of files and still be unreliable. Readiness requires consistent claims supported by evidence."),
              LessonSection("Use the approved submission workflow.",
                  "Follow the responsible authority’s system of record, required reviews, roles, signatures, and submission steps. In eMASS or another tool, the records still need the same substance.\n\nThis catalog uses a generic record workflow. Actual screens and submission permissions depend on the environment; no live government submission is part of the training."),
              LessonSection("A package consistency review",
                  "SSP: Describes 14 in-scope hosts.\n\nAssessment: Documents testing for 12 hosts.\n\nReview: Determine whether the mismatch is a boundary error, an assessment limitation, or a recent change.\n\nResolve: Reconcile the records and explain the effect before requesting a decision."),
              LessonSection("Build",
                  "Assemble an executive summary, security and applicable privacy planning material, assessment reports, POA&M, and required supporting references. Add a versioned manifest and review record."),
              LessonSection("Prove",
                  "Reconcile control identifiers, asset counts, findings, dates, and status across the SSP, SCTM, SAR, and POA&M. Demonstrate a generic eMASS-style record workflow using training data.")
            ],
            question:
                "The SSP and SAR list different assets. What should happen before submission?",
            answers: [
              "Submit both without explanation.",
              "Resolve or explicitly document the scope difference and its assessment impact.",
              "Delete the inventory from the package."
            ],
            correctAnswer: 1,
            explanation:
                "Reviewers need a coherent picture of the system and the scope actually assessed.",
            sourceUrl:
                "https://securebydesigninc.com/training/rmf/index.html#catalog/10",
            sourceLabel: 'Open the complete guide'),
        Lesson(
            id: "training:rmf-boe-ato:11",
            title: "11 · Present the authorization decision",
            minutes: 90,
            summary:
                "Communicate mission need, the assessed security posture, unresolved risk, and proposed risk responses to the decision maker.",
            sections: [
              LessonSection("Brief what matters for the decision.",
                  "Explain the system’s mission, assessed posture, significant unresolved risks, proposed responses, and any constraints. Keep the detailed evidence accessible behind the summary.\n\nA useful briefing distinguishes verified results from open questions. Avoid overwhelming the decision maker with raw tool output without explaining its significance."),
              LessonSection("Answer questions with an evidence trail.",
                  "Be ready to explain who owns a risk, what evidence supports a conclusion, what remains unresolved, and what a proposed corrective action would change.\n\nA request for more evidence may lead to clarification, additional assessment, or remediation. Treat the review as part of the risk decision process."),
              LessonSection("Record the decision and its conditions.",
                  "The AO issues the decision within their authority. Capture its scope, conditions, monitoring expectations, and review triggers in the required records.\n\nA favorable decision does not freeze the system or end monitoring. The team must understand the operating conditions and carry them into continuing work."),
              LessonSection("Brief an unresolved finding",
                  "Mission: Describe what the system enables and why the capability is needed.\n\nRisk: Explain the effect of an unverified source of privileged activity.\n\nResponse: Present the planned corrective action, owner, verification approach, and remaining uncertainty.\n\nDecision: Support the AO’s evaluation; do not substitute a course score for authorization."),
              LessonSection("Build",
                  "Prepare a five minute briefing and a fictional decision exercise. Capture the system scope, major risks, recommended actions, conditions, monitoring expectations, and next review triggers."),
              LessonSection("Prove",
                  "Defend one unresolved finding and answer a request for additional evidence. Explain why a complete package or a passing score does not automatically produce an ATO.")
            ],
            question: "Who makes the authorization decision?",
            answers: [
              "The product vendor.",
              "The course instructor.",
              "The responsible Authorizing Official."
            ],
            correctAnswer: 2,
            explanation:
                "The assessment informs the decision; the AO has the authorization responsibility.",
            sourceUrl:
                "https://securebydesigninc.com/training/rmf/index.html#catalog/11",
            sourceLabel: 'Open the complete guide'),
        Lesson(
            id: "training:rmf-boe-ato:12",
            title: "12 · Monitor and maintain authorization",
            minutes: 90,
            summary:
                "Keep the authorization evidence useful as the system, threats, personnel, and dependencies change.",
            sections: [
              LessonSection(
                  "Choose measures that support continuing decisions.",
                  "A monitoring strategy defines what is reviewed, who reviews it, how often, what evidence is retained, and which conditions require escalation. Align frequencies with the applicable direction and risk.\n\nMonitor implementation and effectiveness, not only tool availability. Track changes in threats, dependencies, and system use."),
              LessonSection("Evaluate the effect of a change.",
                  "A new component, mission dependency, control-provider change, or incident may affect the prior assessment and authorization basis. Identify the affected controls and records.\n\nFollow the authority’s process to determine the needed reassessment, notifications, or authorization action. Not every change has the same consequence."),
              LessonSection("Keep the package synchronized.",
                  "Update the inventory, architecture, SSP, traceability records, assessment results, and POA&M as appropriate. Preserve the relevant history and review approvals.\n\nContinuous monitoring keeps risk information useful. It does not mean every control is tested constantly or that a particular authorization remains valid regardless of change."),
              LessonSection("A new server enters the boundary",
                  "Change: Document the service, owner, information flow, and approved configuration.\n\nImpact: Identify the affected inventory, control implementations, logging, scanning, backup, and dependencies.\n\nValidate: Collect relevant evidence and complete the required review.\n\nMaintain: Update package records and engage the designated authority when required."),
              LessonSection("Build",
                  "Create a monitoring schedule with owners, evidence sources, review frequencies, escalation criteria, and update triggers. Add a change-impact record and an updated package version."),
              LessonSection("Prove",
                  "Process a new server, a missed security update, and a changed common control. Determine what must be revalidated, what artifacts change, and when the AO or designated authority must be engaged.")
            ],
            question:
                "A new service changes a documented information flow. What should the team do?",
            answers: [
              "Wait until the next major rewrite.",
              "Evaluate the change, update affected evidence, and follow the required review process.",
              "Assume the existing ATO covers every future service."
            ],
            correctAnswer: 1,
            explanation:
                "Changes must be evaluated against the assessed and authorized scope.",
            sourceUrl:
                "https://securebydesigninc.com/training/rmf/index.html#catalog/12",
            sourceLabel: 'Open the complete guide')
      ])
];
